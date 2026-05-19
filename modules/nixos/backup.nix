{ config, pkgs, ... }:

# Duplicati — encrypted backups to cloud / remote / local destinations.
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

{
  services.duplicati = {
    enable = true;
    # Default port (8200) and interface (127.0.0.1) — leave un-overridden so
    # the UI is local-only. To expose to LAN, set `interface = "any"` and
    # open the firewall, but Duplicati's auth is a single password so prefer
    # tunneling over SSH or Tailscale instead.
    user = "duplicati";
    # Storage location for the server's job database, lock files, and any
    # local backup destinations.
    dataDir = "/var/lib/duplicati";
  };

  environment.systemPackages = [
    pkgs.duplicati     # CLI + server (used by services.duplicati)
    pkgs.duplicati-gui # GUI / system-tray (overlay-built AppImage wrap)
  ];
}
