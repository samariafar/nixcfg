{ config, pkgs, ... }:

# Syncthing — continuous peer-to-peer folder synchronisation.
#
# Architecture: `services.syncthing` runs `syncthing` as a systemd unit. We
# run it as `sam`:`users` rather than the module's default `syncthing` system
# user so synced folders land in the real home directory with the right
# ownership and no cross-user permission dance.
#
# ATTENTION: `dataDir` MUST stay inside /home/sam. The module only creates
# the directory (`users.users.syncthing.createHome`) when `user` is left at
# its default; with `user = "sam"` nothing pre-creates it, and sam cannot
# mkdir inside root-owned /var/lib — so the default `/var/lib/syncthing`
# makes the unit fail on first start.
#
# The web UI stays on the `guiAddress` default (127.0.0.1:8384) — local-only.
# `openDefaultPorts` opens only the sync/discovery ports (22000 TCP+UDP,
# 21027/udp), never the UI.

{
  services.syncthing = {
    enable = true;
    user = "sam";
    group = "users";
    # Synced folders live here; configDir/databaseDir derive from this as
    # `${dataDir}/.config/syncthing` (stateVersion >= 19.03).
    dataDir = "/home/sam";
    openDefaultPorts = true;
  };

  # Duplicati — encrypted backups to cloud / remote / local destinations.
  # Superseded by Syncthing above; kept for reference in case we switch back.
  #
  # Architecture: `services.duplicati` runs `duplicati-server` as a systemd
  # unit owned by the `duplicati` system user; the binary listens on
  # localhost only and exposes a web UI for browse/configure/schedule.
  #
  # nixpkgs only ships the `-cli.zip` server+CLI variant as `pkgs.duplicati`
  # (no tray icon). The upstream `-gui.appimage` (Avalonia + .NET 10) is
  # wrapped via `overlays/duplicati-gui.nix` and exposed as
  # `pkgs.duplicati-gui`; the per-user tray autostart lives in
  # `modules/home-manager/programs/gui/duplicati.nix` and connects to this
  # systemd-managed server with `--no-hosted-server`.
  #
  # Re-enabling needs all four of: this block, the overlay import in
  # flake.nix, the home-manager import in users/sam/home.nix, and the
  # `com.duplicati.app.desktop` entry in modules/home-manager/dconf.nix.
  #
  #services.duplicati = {
  #  enable = true;
  #  # Default port (8200) and interface (127.0.0.1) — leave un-overridden so
  #  # the UI is local-only. To expose to LAN, set `interface = "any"` and
  #  # open the firewall, but Duplicati's auth is a single password so prefer
  #  # tunneling over SSH or Tailscale instead.
  #  user = "duplicati";
  #  # Storage location for the server's job database, lock files, and any
  #  # local backup destinations.
  #  dataDir = "/var/lib/duplicati";
  #};

  #environment.systemPackages = [
  #  pkgs.duplicati     # CLI + server (used by services.duplicati)
  #  pkgs.duplicati-gui # GUI / system-tray (overlay-built AppImage wrap)
  #];
}
