{ pkgs, ... }:

# Duplicati tray-icon autostart. Connects to the systemd-managed
# `duplicati-server` running on localhost:8200 (configured in
# `modules/nixos/backup.nix`) — `--no-hosted-server` keeps the tray from
# spawning its own duplicate server, and `--hosturl` pins the target so
# the tray never falls back to launching one.
#
# First launch will prompt once for the server password (set via the web
# UI on initial setup) and persist credentials under
# `~/.config/Duplicati/`. Subsequent logins start silent.

{
  xdg.configFile."autostart/duplicati-tray.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Duplicati Tray
    Comment=Backup tool tray icon (connects to local duplicati-server)
    Exec=${pkgs.duplicati-gui}/bin/duplicati-gui --no-hosted-server --hosturl=http://localhost:8200
    Icon=duplicati
    Terminal=false
    StartupNotify=false
    X-GNOME-Autostart-enabled=true
  '';
}
