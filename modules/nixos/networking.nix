{ config, pkgs, options, ... }:

{
  networking.hostName = "workstation";

  # Prefer Cloudflare's NTP server, then fall back to upstream defaults.
  networking.timeServers = [ "time.cloudflare.com" ] ++ options.networking.timeServers.default;
  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      profiles = {
        home = {
          connection = {
            id = "$HOME_SSID";
            type = "wifi";
            autoconnect = true;
          };
          wifi = {
            ssid = "$HOME_SSID";
            mode = "infrastructure";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$HOME_PSK";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
        office = {
          connection = {
            id = "$OFFICE_SSID";
            type = "wifi";
            autoconnect = true;
          };
          wifi = {
            ssid = "$OFFICE_SSID";
            mode = "infrastructure";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$OFFICE_PSK";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
      environmentFiles = [
        config.sops.secrets."wifi/home".path
        config.sops.secrets."wifi/office".path
      ];
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];

    # SSH is reachable only from the mobile device over Tailscale.
    # - Non-Tailscale interfaces (LAN/Wi-Fi/WAN): blocked by the default
    #   NixOS firewall, since openFirewall = false below.
    # - tailscale0: tailscaled inserts its own `ts-input` chain at the top
    #   of INPUT that accepts tailnet traffic before nixos-fw runs, so the
    #   restriction lives in the raw table (PREROUTING), which runs earlier
    #   and which tailscaled doesn't manage. -D first keeps reloads idempotent.
    # ATTENTION: update the IP if mobile is re-registered on the tailnet.
    extraCommands = ''
      iptables -t raw -D PREROUTING -i tailscale0 -p tcp --dport 7747 ! -s 100.73.8.15 -j DROP 2>/dev/null || true
      iptables -t raw -A PREROUTING -i tailscale0 -p tcp --dport 7747 ! -s 100.73.8.15 -j DROP
      ip6tables -t raw -D PREROUTING -i tailscale0 -p tcp --dport 7747 -j DROP 2>/dev/null || true
      ip6tables -t raw -A PREROUTING -i tailscale0 -p tcp --dport 7747 -j DROP
    '';
    extraStopCommands = ''
      iptables -t raw -D PREROUTING -i tailscale0 -p tcp --dport 7747 ! -s 100.73.8.15 -j DROP 2>/dev/null || true
      ip6tables -t raw -D PREROUTING -i tailscale0 -p tcp --dport 7747 -j DROP 2>/dev/null || true
    '';
  };

  # SSH server: key-only, reachable solely from the mobile device over
  # Tailscale (used by the Herdr mobile app). See firewall rules above.
  services.openssh = {
    enable = true;
    openFirewall = false; # Never expose on LAN/Wi-Fi/WAN
    ports = [ 7747 ]; # Non-standard port

    # Use only modern, secure ed25519 host key
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    settings = {
      # Authentication
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false; # No TOTP prompt (see security.nix)
      PubkeyAuthentication = true;
      PermitEmptyPasswords = false;
      HostbasedAuthentication = false;
      IgnoreRhosts = true;

      # Key-only authentication
      AuthenticationMethods = "publickey";

      # Only user `sam`, and only from mobile's tailnet IP (second layer
      # behind the firewall rule; sshd enforces it regardless of netfilter).
      AllowUsers = [ "sam@100.73.8.15" ];

      # Connection limits
      MaxAuthTries = 3;
      MaxSessions = 2;
      LoginGraceTime = 30;

      # Idle session timeout (5 minutes)
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;

      # Disable forwarding (enable only if needed)
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = "no";
      PermitTunnel = "no";
      GatewayPorts = "no";

      # Modern crypto only
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
      ];
      KexAlgorithms = [
        "sntrup761x25519-sha512@openssh.com" # Hybrid post-quantum KEX
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
      # Plain comma-separated strings: unlike Ciphers/Macs/KexAlgorithms,
      # these aren't list-typed options in the NixOS openssh module.
      HostKeyAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com";
      PubkeyAcceptedAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com";

      # Misc hardening
      UsePAM = true;
      PrintLastLog = true;
      PrintMotd = false;
      Compression = false; # Disable to mitigate CRIME-style attacks
      StrictModes = true;
    };
  };

  # Encrypted DNS via dnscrypt-proxy (Quad9 first, Cloudflare fallback).
  # Renamed from services.dnscrypt-proxy2 in NixOS 25.11.
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      ipv4_servers = true;
      ipv6_servers = true;
      dnscrypt_servers = true;
      doh_servers = true;
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = false; # Quad9 filters malware

      # Server priority: Quad9 first, then Cloudflare
      server_names = [
        "quad9-dnscrypt-ip4-filter-pri" # Quad9 DNSCrypt (filtered, primary)
        "quad9-doh-ip4-port443-filter-pri" # Quad9 DoH (filtered, primary)
        "cloudflare" # Cloudflare DoH
        "cloudflare-ipv6"
      ];

      # Use servers in order of preference (not random)
      lb_strategy = "first";

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };

  # Disable systemd-resolved since dnscrypt-proxy handles DNS
  services.resolved.enable = false;

  # Use dnscrypt-proxy for DNS resolution
  networking.nameservers = [ "127.0.0.1" "::1" ];
  networking.dhcpcd.extraConfig = "nohook resolv.conf";
  networking.networkmanager.dns = "none";
}
