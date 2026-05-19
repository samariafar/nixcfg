{ config, pkgs, lib, ... }:

{
  # GNOME + GDM moved out of services.xserver in NixOS 25.11.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver = {
    enable = true;

    xkb = {
      layout = lib.concatStringsSep "," [
        "us"
        "ir"
      ];
      variant = lib.concatStringsSep "," [
        ""           # us
        "pes_keypad" # ir
      ];
      options = lib.concatStringsSep "," [
        "compose:ralt"
        "grp:alt_shift_toggle"
        "lv3:lalt_switch"
      ];
    };
  };

  # Touchpad / pointer input (canonical 25.11 path; the old
  # services.xserver.libinput.enable is now an alias for this)
  services.libinput.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Fingerprint authentication
  services.fprintd.enable = true;

  # PipeWire audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
  };

  services.gnome.gnome-keyring.enable = true;

  # Printing — HP printers via USB and network. hplipWithPlugin pulls in the
  # proprietary HP plugin for wider device coverage (use plain `hplip` if you
  # prefer a fully-FOSS driver at the cost of some LaserJet/OfficeJet models).
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  # mDNS service discovery — required for AirPrint / IPP-Everywhere network
  # printers to auto-appear, and for resolving *.local hostnames.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Exclude GNOME bloat
  environment.gnome.excludePackages = with pkgs; [
    baobab
    epiphany
    geary
    gnome-connections
    gnome-console
    gnome-maps
    gnome-music
    gnome-system-monitor
    gnome-tour
    shotwell
    simple-scan
    totem
    yelp
  ];

  environment.systemPackages = with pkgs; [
    dconf-editor
    gnome-extension-manager
    # gnome-terminal  # Switched to Ptyxis
    gnome-tweaks
    gnome-weather
    nautilus-open-any-terminal # adds "Open in Terminal" to Nautilus context menu
    nautilus-python # required by nautilus-open-any-terminal to load Python extensions
    ptyxis
  ] ++ (with pkgs.gnomeExtensions; [
    appindicator
    claudebar
    clipboard-indicator
    dash-to-dock
    desktop-icons-ng-ding # rastersoft's original; GTK4 fork didn't work
    hide-activities-button
    night-theme-switcher
    pip-on-top # rafostar's; UUID pip-on-top@rafostar.github.com
    top-bar-organizer
    tophat
    weather-oclock
    workspace-indicator

    # Available but disabled — pulled from previous configs for future review.
    # control-blur-effect-on-lock-screen
    # cronomix
    # date-menu-formatter
    # gtk4-desktop-icons-ng-ding   # smedius GTK4 fork; tried, didn't work — using rastersoft above
    # gmeet
    # gtile
    # hibernate-status-button
    # krypto
    # unlock-dialog-background
  ]);

  # Auto-login
  # services.xserver.displayManager.autoLogin = {
  #   enable = true;
  #   user = "sam";
  # };
}
