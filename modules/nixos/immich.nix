{ config, pkgs, ... }:

{
  services.immich = {
    enable = true;
    host = "0.0.0.0"; # Listen on all interfaces (firewall restricts access)
    port = 2283;
    mediaLocation = "/var/lib/immich"; # TODO: Change to ~/Pictures/Archive/

    # Auto-sets up postgres with pgvecto.rs and redis
    database.enable = true;
    redis.enable = true;
    machine-learning.enable = true; # Face recognition, smart search
  };

  # Allow Immich access only via Tailscale (not exposed to LAN/WAN)
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 2283 ];

  # Ensure immich service starts after Tailscale
  systemd.services.immich-server.after = [ "tailscaled.service" ];

  # External Library disabled — re-add the line below if you ever expose a
  # user-owned directory (e.g., ~/Pictures) to Immich via External Library:
  # users.users.immich.extraGroups = [ "users" ];
}
