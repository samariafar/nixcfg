{ config, pkgs, lib, ... }:

{
  # AppArmor (Mandatory Access Control)
  # ATTENTION: Not enabled by default on NixOS (unlike Ubuntu)
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };

  # TOTP 2FA via PAM (Google Authenticator compatible)
  # ATTENTION: Run `google-authenticator` as your user to generate TOTP secret
  # before enabling SSH, otherwise you'll be locked out
  security.pam.services.sshd.googleAuthenticator.enable = true;

  # Sudo hardening (5-minute timeout)
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=5
    Defaults lecture=once
  '';

  # Kernel audit framework (logs security-relevant events)
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      "-a exit,always -F arch=b64 -S execve" # Log all command executions
    ];
  };

  # Kernel hardening via sysctl (safe defaults that don't break things)
  boot.kernel.sysctl = {
    # Network hardening
    "net.ipv4.tcp_syncookies" = 1; # SYN flood protection
    "net.ipv4.tcp_rfc1337" = 1; # TIME-WAIT assassination protection
    "net.ipv4.conf.default.rp_filter" = 1; # Reverse path filtering
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.accept_source_route" = 0; # Disable source routing
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0; # Disable ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0; # Don't send redirects
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Ignore ICMP broadcasts
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.conf.all.log_martians" = 1; # Log spoofed / impossible-source packets
    "net.ipv4.conf.default.log_martians" = 1;

    # Kernel hardening
    "kernel.dmesg_restrict" = 1; # Restrict dmesg access
    "kernel.kexec_load_disabled" = 1; # Block post-boot kernel replacement via kexec
    "kernel.kptr_restrict" = 2; # Hide kernel pointers
    "kernel.yama.ptrace_scope" = 1; # Restrict ptrace to direct children
    "kernel.unprivileged_bpf_disabled" = 1; # Disable unprivileged BPF
  };

  # USBGuard (control USB device permissions - important for laptops)
  # Disabled for now — default policy blocks unknown devices, which made
  # USB dongles invisible to Disks/Files. Re-enable and seed the policy
  # via `sudo usbguard generate-policy | sudo tee /var/lib/usbguard/rules.conf`
  # before turning it back on, or use `usbguard allow-device -p <id>` per device.
  # services.usbguard = {
  #   enable = true;
  #   dbus.enable = true;
  #   presentDevicePolicy = "apply-policy"; # Use rules for already-connected devices
  #   presentControllerPolicy = "keep"; # Don't change controllers
  # };

  # Fail2ban (block brute-force attempts)
  # NOTE: SSH is currently disabled, but jail is configured for when enabled
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    bantime-increment = {
      enable = true; # Increase ban time for repeat offenders
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # 1 week max
    };
    jails = {
      sshd.settings = {
        enabled = true;
        maxretry = 5;
      };
      # Monitor TTY/local login attempts
      login.settings = {
        enabled = true;
        filter = "login";
        logpath = "/var/log/auth.log";
        maxretry = 5;
      };
    };
  };

  # Firejail (Application sandboxing)
  programs.firejail.enable = true;

  # OpenSnitch (Per-app firewall)
  services.opensnitch.enable = true;

  # ClamAV antivirus
  services.clamav = {
    daemon.enable = true; # Real-time scanning daemon
    updater.enable = true; # Auto-update virus signatures
  };

  environment.systemPackages = with pkgs; [
    # chkrootkit  # Removed from nixpkgs — upstream unmaintained/archived
    # and reportedly never worked correctly on NixOS. rkhunter below covers
    # the same role.
    google-authenticator # TOTP setup tool
    lynis # Security auditing tool
    # rkhunter  # Removed from nixpkgs — upstream unmaintained, same fate
    # as chkrootkit. No drop-in nixpkgs replacement; rely on AppArmor +
    # auditd + ClamAV for now.
  ];
}
