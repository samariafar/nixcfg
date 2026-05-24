{ lib, ... }:

# Declarative GNOME (and friends) settings via dconf.
#
# This module is the home-manager superset distilled from previous nixos
# configs. Active blocks reflect the extension picks currently enabled in
# modules/nixos/desktop.nix. Disabled / machine-specific / extension-not-yet-
# enabled blocks are commented out with notes — uncomment once you add the
# matching extension package or you've decided to opt in.
#
# ATTENTION: Run `gnome-extensions list` after first boot to confirm the
# UUID strings below match what your installed extension packages actually
# register. If anything fails to take effect, the UUID is the most likely
# culprit.

let
  # `app-picker-layout` is gvariant `aa{sv}` — array of dict<string,variant>,
  # where each value is itself a variant containing `a{sv}` like {'position': <N>}.
  # lib.gvariant doesn't auto-convert attrsets to dicts, so we build the
  # `{'position': <N>}` payload via mkDictionaryEntry. Helper keeps the
  # call-site below readable.
  pickerPos =
    idx:
    lib.gvariant.mkVariant [
      (lib.gvariant.mkDictionaryEntry "position" (lib.gvariant.mkVariant (lib.gvariant.mkInt32 idx)))
    ];
in
{
  dconf.settings = with lib.gvariant; {
    # ----------------------------------------------------------------------
    # Locale & input
    # ----------------------------------------------------------------------

    "system/locale".region = "nl_NL.UTF-8";

    # Two input sources: default US, plus Persian with numeric keypad.
    # Keymap options here mirror modules/nixos/desktop.nix services.xserver.xkb
    # so X11 and GNOME runtime agree.
    "org/gnome/desktop/input-sources" = {
      sources = [
        (mkTuple [ "xkb" "us" ])
        (mkTuple [ "xkb" "ir+pes_keypad" ])
      ];
      xkb-options = [
        "compose:ralt"
        "grp:alt_shift_toggle"
        "lv3:lalt_switch"
        "terminate:ctrl_alt_bksp"
      ];
    };

    "org/gnome/desktop/peripherals/keyboard".numlock-state = true;

    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = false;
      two-finger-scrolling-enabled = true;
    };

    # ----------------------------------------------------------------------
    # Privacy / location
    # ----------------------------------------------------------------------

    "org/gnome/system/location" = {
      enabled = true;
      max-accuracy-level = "city";
    };

    "org/gnome/desktop/notifications".show-in-lock-screen = false;

    # Break reminders — eye/movement breaks every 30 min, 5 min long, with sound.
    "org/gnome/desktop/break-reminders/eyesight".play-sound = true;
    "org/gnome/desktop/break-reminders/movement" = {
      duration-seconds = mkUint32 300;
      interval-seconds = mkUint32 1800;
      play-sound = true;
    };

    # Settings search-provider order in the Activities/search overlay.
    "org/gnome/desktop/search-providers".sort-order = [
      "org.gnome.Settings.desktop"
      "org.gnome.Contacts.desktop"
      "org.gnome.Nautilus.desktop"
    ];

    "org/gnome/desktop/privacy" = {
      old-files-age = mkUint32 2;
      remember-recent-files = false;
      remove-old-temp-files = true;
      remove-old-trash-files = true;
    };

    # ----------------------------------------------------------------------
    # Shell — extensions
    # ----------------------------------------------------------------------

    "org/gnome/shell" = {
      # Match the active list in modules/nixos/desktop.nix.
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "claudebar@bilbilak.org"
        "clipboard-indicator@tudmotu.com"
        "dash-to-dock@micxgx.gmail.com"
        "ding@rastersoft.com" # tried gtk4-ding (smedius), didn't work
        # nixpkgs `hide-activities-button` ships the shay.shayel.org fork
        # (NOT the shyzus.github.io fork from EGO). Confirmed via
        # `gnome-extensions list`.
        "Hide_Activities@shay.shayel.org"
        "nightthemeswitcher@romainvigier.fr"
        "pip-on-top@rafostar.github.com"
        "top-bar-organizer@julian.gse.jsts.xyz"
        "tophat@fflewddur.github.io"
        "weatheroclock@CleoMenezesJr.github.io"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
      ];

      # Default-shipped GNOME extensions we want force-off.
      disabled-extensions = [
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
        "light-style@gnome-shell-extensions.gcampax.github.com"
        "native-window-placement@gnome-shell-extensions.gcampax.github.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "window-list@gnome-shell-extensions.gcampax.github.com"
        "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
      ];

      # ATTENTION: NOT alphabetical — this is the user's chosen Dock pin order
      # (left → right). Don't sort.
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "org.gnome.Ptyxis.desktop"
        "org.gnome.Calculator.desktop"
        "com.vixalien.sticky.desktop"
        "io.github.alainm23.planify.desktop"
        "thunderbird.desktop"
        "firefox.desktop"
      ];

      last-selected-power-profile = "balanced";

      # ATTENTION: NOT alphabetical — this is the user's chosen App Launcher
      # page-1 order (top-left → bottom-right). Don't sort. Folders absent
      # here (Pardus, System, YaST) are GNOME stock placeholders kept defined
      # in folder-children to suppress the empty stock slots; they'll fall to
      # the end if/when GNOME chooses to render them.
      app-picker-layout = [
        [
          (mkDictionaryEntry "Internet" (pickerPos 0))
          (mkDictionaryEntry "Office" (pickerPos 1))
          (mkDictionaryEntry "Development" (pickerPos 2))
          (mkDictionaryEntry "Engineering" (pickerPos 3))
          (mkDictionaryEntry "Graphics" (pickerPos 4))
          (mkDictionaryEntry "Media" (pickerPos 5))
          (mkDictionaryEntry "Virtualization" (pickerPos 6))
          (mkDictionaryEntry "Remote" (pickerPos 7))
          (mkDictionaryEntry "Security" (pickerPos 8))
          (mkDictionaryEntry "Accessories" (pickerPos 9))
          (mkDictionaryEntry "Monitor" (pickerPos 10))
          (mkDictionaryEntry "SystemTools" (pickerPos 11))
        ]
      ];
    };

    "org/gnome/shell/app-switcher".current-workspace-only = true;

    # ----------------------------------------------------------------------
    # Per-extension settings (active extensions only)
    # ----------------------------------------------------------------------

    "org/gnome/shell/extensions/appindicator" = {
      icon-opacity = mkInt32 240;
      tray-pos = "left";
    };

    "org/gnome/shell/extensions/clipboard-indicator" = {
      enable-keybindings = false;
      paste-button = false;
      strip-text = true;
    };

    "org/gnome/shell/extensions/nightthemeswitcher/commands" = {
      enabled = true;
      sunrise = "gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'";
      sunset = "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'";
    };

    # Manual on-demand toggle (Shift+Super+T). Sunrise/sunset/location are
    # auto-derived from geoclue and intentionally not pinned here.
    "org/gnome/shell/extensions/nightthemeswitcher/time".nightthemeswitcher-ondemand-keybinding = [
      "<Shift><Super>t"
    ];

    "org/gnome/shell/extensions/top-bar-organizer" = {
      center-box-order = [ "dateMenu" ];
      left-box-order = [
        "activities"
        "workspace-indicator"
        "claudebar@bilbilak.org"
        "appindicator-kstatusnotifieritem-zero-trust-client"
        "appindicator-kstatusnotifieritem-blueman"
      ];
      right-box-order = [
        "TopHat"
        "screenRecording"
        "clipboardIndicator"
        "screenSharing"
        "dwellClick"
        "a11y"
        "keyboard"
        "quickSettings"
      ];
    };

    "org/gnome/shell/extensions/weather-oclock".weather-after-clock = true;

    "org/gnome/shell/extensions/tophat" = {
      cpu-show-cores = true;
      cpu-sort-cores = false;
      mem-abs-units = false;
      mount-to-monitor = "/home";
      network-usage-unit = "bits";
      position-in-panel = "right";
      show-disk = true;
      show-net = true;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      apply-custom-theme = false;
      background-opacity = 0.8;
      click-action = "minimize";
      custom-theme-shrink = true;
      dash-max-icon-size = 42;
      dock-position = "BOTTOM";
      height-fraction = 0.9;
      preferred-monitor = mkInt32 (-2); # -2 = primary monitor (portable)
      running-indicator-style = "DOTS";
      scroll-action = "cycle-windows";
      show-mounts = false;
      show-mounts-only-mounted = false;
    };

    # Per-extension settings for inactive picks. Uncomment when the matching
    # extension is added back to modules/nixos/desktop.nix.
    #
    # "org/gnome/shell/extensions/date-menu-formatter" = {
    #   use-default-locale = false;
    #   custom-locale = "en-US";
    #   pattern = "EEEE, MMM d  HH:mm";
    #   font-size = 11;
    # };
    #
    "org/gnome/shell/extensions/ding" = {
      arrangeorder = "KIND";
      check-x11wayland = true;
      dark-text-in-labels = false;
      icon-size = "tiny";
      keep-arranged = true;
      show-home = false;
      show-trash = false;
      show-volumes = false;
    };

    "org/gnome/shell/extensions/pip-on-top".stick = true;
    #
    # "org/gnome/shell/extensions/sticky-notes-integration" = {
    #   panel-indicator-position = 0;
    #   panel-indicator-position-order = 2;
    #   show-open-note-count = true;
    # };
    #
    # "org/gnome/shell/extensions/unlock-dialog-background" = {
    #   picture-uri = "/home/sam/Pictures/Wallpapers/login-screen-bg.jpg";
    #   picture-uri-dark = "/home/sam/Pictures/Wallpapers/login-screen-bg.jpg";
    # };
    #
    # "org/gnome/shell/extensions/weatherornot".position = "clock-right-centered";

    # ----------------------------------------------------------------------
    # App picker — folders
    # ----------------------------------------------------------------------
    #
    # GNOME's app picker renders these folders in `folder-children` order.
    # Folder identifiers are arbitrary strings; legacy GNOME-shipped folders
    # (System / Utilities / YaST / Pardus) override the defaults shipped by
    # the shell, while the human-readable IDs below are user-defined groups.
    # Apps whose .desktop files aren't installed are silently skipped, so
    # leaving entries for not-yet-installed packages is safe.

    "org/gnome/desktop/app-folders".folder-children = [
      "Accessories"
      "Development"
      "Engineering"
      "Graphics"
      "Internet"
      "Media"
      "Monitor"
      "Office"
      "Pardus"
      "Remote"
      "Security"
      "System"
      "SystemTools"
      "Virtualization"
      "YaST"
    ];

    # ATTENTION: NOT alphabetical — user's chosen in-folder order. Don't sort.
    "org/gnome/desktop/app-folders/folders/Accessories" = {
      apps = [
        "org.gnome.clocks.desktop"
        "org.gnome.Calendar.desktop"
        "org.gnome.Contacts.desktop"
        "org.gnome.Weather.desktop"
        "org.gnome.TextEditor.desktop"
        "com.belmoussaoui.Decoder.desktop"
        "tech.digiroad.Convertidor.desktop"
        "org.gnome.font-viewer.desktop"
        "com.rafaelmardojai.Blanket.desktop"
        "com.github.FontManager.FontManager.desktop"
        "com.github.FontManager.FontViewer.desktop"
        "org.gnome.Characters.desktop"
      ];
      name = "Accessories";
      translate = false;
    };

    # ATTENTION: NOT alphabetical — user's chosen in-folder order. Don't sort.
    "org/gnome/desktop/app-folders/folders/Development" = {
      apps = [
        "webstorm.desktop"
        "rust-rover.desktop"
        "pycharm.desktop"
        "goland.desktop"
        "clion.desktop"
        "phpstorm.desktop"
        "rider.desktop"
        "idea.desktop"
        "android-studio.desktop"
        "dev.zed.Zed.desktop"
        "lm-studio.desktop"
        "bruno.desktop"
        "gitkraken.desktop"
        "SourceGit.desktop"
        "imhex.desktop"
        "io.gitlab.liferooter.TextPieces.desktop"
        "chromium-browser.desktop"
      ];
      name = "Development";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/Engineering" = {
      apps = [
        "org.freecad.FreeCAD.desktop"
        "org.kicad.kicad.desktop"
        "org.kicad.eeschema.desktop"
        "org.kicad.pcbnew.desktop"
        "org.kicad.gerbview.desktop"
        "org.kicad.bitmap2component.desktop"
        "org.kicad.pcbcalculator.desktop"
      ];
      name = "Engineering";
      translate = false;
    };

    # ATTENTION: NOT alphabetical — user's chosen in-folder order. Don't sort.
    "org/gnome/desktop/app-folders/folders/Graphics" = {
      apps = [
        "org.kde.krita.desktop"
        "org.inkscape.Inkscape.desktop"
        "com.github.finefindus.eyedropper.desktop"
        "com.github.huluti.Curtail.desktop"
        "be.alexandervanhee.gradia.desktop"
        "org.gnome.gitlab.YaLTeR.VideoTrimmer.desktop"
      ];
      name = "Graphics";
      translate = false;
    };

    # ATTENTION: NOT alphabetical — user's chosen in-folder order. Don't sort.
    "org/gnome/desktop/app-folders/folders/Internet" = {
      apps = [
        "Cinny.desktop"
        "io.gitlab.news_flash.NewsFlash.desktop"
        "app.drey.Warp.desktop"
      ];
      name = "Internet";
      translate = false;
    };

    # Overrides GNOME's default `Utilities` folder slot — repurposed as Media.
    # ATTENTION: NOT alphabetical — user's chosen in-folder order. Don't sort.
    "org/gnome/desktop/app-folders/folders/Media" = {
      apps = [
        "org.gnome.Papers.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.Decibels.desktop"
        "org.gnome.Showtime.desktop"
        "org.gnome.Snapshot.desktop"
        "vlc.desktop"
        "com.obsproject.Studio.desktop"
      ];
      name = "Media";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/Monitor" = {
      apps = [
        "net.nokyan.Resources.desktop"
        "org.gnome.Sysprof.desktop"
        "org.gnome.Logs.desktop"
        "htop.desktop"
        "btop.desktop"
      ];
      name = "Monitor";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/Office" = {
      apps = [
        "obsidian.desktop"
        "writer.desktop"
        "calc.desktop"
        "impress.desktop"
        "draw.desktop"
        "base.desktop"
        "math.desktop"
        "org.nickvision.money.desktop"
        "app.tintero.Tintero.desktop"
        "startcenter.desktop"
      ];
      name = "Office";
      translate = false;
    };

    # Overrides GNOME default — Pardus distribution apps category, kept
    # disabled-but-defined to suppress the empty stock folder on fresh
    # installs.
    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    # ATTENTION: NOT alphabetical — user's chosen in-folder order. Don't sort.
    "org/gnome/desktop/app-folders/folders/Remote" = {
      apps = [
        "org.remmina.Remmina.desktop"
        "rustdesk.desktop"
        "com.teamviewer.TeamViewer.desktop"
        "org.gnome.NetworkDisplays.desktop"
      ];
      name = "Remote";
      translate = false;
    };

    # ATTENTION: NOT alphabetical — user's chosen in-folder order. Don't sort.
    "org/gnome/desktop/app-folders/folders/Security" = {
      apps = [
        "io.github.linx_systems.ClamUI.desktop"
        "org.cryptomator.Cryptomator.desktop"
        "com.github.ADBeveridge.Raider.desktop"
        "fr.romainvigier.MetadataCleaner.desktop"
        "com.belmoussaoui.Obfuscate.desktop"
        "com.cloudflare.WarpTaskbar.desktop"
        "proton-bridge-gui.desktop"
        "org.gnome.seahorse.Application.desktop"
      ];
      name = "Security";
      translate = false;
    };

    # Overrides GNOME's default `System` folder.
    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [
        "org.gnome.baobab.desktop"
        "org.gnome.SystemMonitor.desktop"
      ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    # Custom system tools / settings folder (separate from the GNOME-default
    # `System` slot above so the two display-name conventions don't collide).
    "org/gnome/desktop/app-folders/folders/SystemTools" = {
      apps = [
        "org.gnome.Settings.desktop"
        "org.gnome.tweaks.desktop"
        "org.gnome.Software.desktop"
        "ca.desrt.dconf-editor.desktop"
        "com.mattjakeman.ExtensionManager.desktop"
        "org.gnome.Extensions.desktop"
        "org.gnome.DiskUtility.desktop"
        "com.duplicati.app.desktop"
        "org.gnome.World.PikaBackup.desktop"
        "blueman-manager.desktop"
        "cups.desktop"
        "nixos-manual.desktop"
        "xterm.desktop"
      ];
      name = "System";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/Virtualization" = {
      apps = [
        "virt-manager.desktop"
        "winboat.desktop"
      ];
      name = "Virtualization";
      translate = false;
    };

    # Overrides GNOME default — openSUSE YaST category, kept defined to
    # suppress the empty stock folder.
    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    # ----------------------------------------------------------------------
    # Window manager / mutter
    # ----------------------------------------------------------------------

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      num-workspaces = 6;
    };

    "org/gnome/mutter" = {
      center-new-windows = true;
      dynamic-workspaces = false; # pin to num-workspaces above (6)
      workspaces-only-on-primary = true;
    };

    # ----------------------------------------------------------------------
    # Power / colour
    # ----------------------------------------------------------------------

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "nothing";
      sleep-inactive-ac-type = "nothing"; # never auto-suspend on AC
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-temperature = mkUint32 3700;
    };

    # ----------------------------------------------------------------------
    # Sound
    # ----------------------------------------------------------------------

    "org/gnome/desktop/sound".allow-volume-above-100-percent = true;

    # ----------------------------------------------------------------------
    # Interface
    # ----------------------------------------------------------------------

    "org/gnome/desktop/interface" = {
      accent-color = "blue";
      clock-show-weekday = true;
      # nightthemeswitcher flips this at sunrise/sunset; "prefer-dark" is the
      # baseline for fresh sessions before the first sunset trigger fires.
      color-scheme = "prefer-dark";
      enable-hot-corners = true;
      show-battery-percentage = true;
    };

    "org/gnome/desktop/calendar".show-weekdate = true;

    # ----------------------------------------------------------------------
    # Background / lock screen
    # ----------------------------------------------------------------------

    # NixOS-shipped GNOME wallpaper (resolved at runtime via /run/current-system,
    # so the path is portable across machines/generations).
    "org/gnome/desktop/background" = {
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/pixel-pusher-l.jxl";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/pixel-pusher-d.jxl";
      primary-color = "#967864";
    };

    "org/gnome/desktop/screensaver" = {
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/pixel-pusher-l.jxl";
      primary-color = "#967864";
    };

    # ----------------------------------------------------------------------
    # Nautilus
    # ----------------------------------------------------------------------

    "org/gnome/nautilus/preferences" = {
      date-time-format = "detailed";
      default-folder-viewer = "icon-view";
      show-create-link = true;
      show-delete-permanently = true;
    };

    "org/gnome/nautilus/icon-view".default-zoom-level = "small";

    "com/github/stunkymonkey/nautilus-open-any-terminal" = {
      terminal = "ptyxis";
      new-tab = true;
      use-generic-terminal-name = true; # "Open Terminal Here" instead of "Open Ptyxis Here"
    };

    # Default terminal for desktop "Open in Terminal" (desktop-icons-ng-ding)
    "org/gnome/desktop/default-applications/terminal" = {
      exec = "ptyxis";
      exec-arg = "--";
    };

    # GTK4 + legacy GTK3 file choosers
    "org/gtk/gtk4/settings/file-chooser".show-hidden = true;
    "org/gtk/settings/file-chooser".show-hidden = true;

    # ----------------------------------------------------------------------
    # Apps
    # ----------------------------------------------------------------------

    "org/gnome/calculator" = {
      accuracy = mkInt32 5;
      favorite-currencies = [ "EUR" "GBP" "USD" ];
      show-thousands = true;
      refresh-interval = mkUint32 86400;
    };

    "org/gnome/TextEditor" = {
      highlight-current-line = true;
      indent-style = "space";
      show-line-numbers = true;
      spellcheck = false;
      tab-width = mkUint32 4;
    };

    "org/gnome/Totem".repeat = true;

    # Ptyxis stores per-profile settings under a generated UUID. Pinning the
    # UUID here makes the "Custom" profile reproducible across machines —
    # any value works, the string just has to match between the three keys
    # (default-profile-uuid, profile-uuids list, and the /Profiles/<UUID> path).
    "org/gnome/Ptyxis" = {
      audible-bell = false;
      default-profile-uuid = "b53f399a2fbcf38ced6e3b2b69fb8e58";
      interface-style = "system";
      profile-uuids = [ "b53f399a2fbcf38ced6e3b2b69fb8e58" ];
      restore-session = false;
      restore-window-size = false;
      window-size = mkTuple [ (mkUint32 80) (mkUint32 24) ];
    };

    "org/gnome/Ptyxis/Profiles/b53f399a2fbcf38ced6e3b2b69fb8e58" = {
      label = "Custom";
      scroll-on-keystroke = true;
    };

    "org/gnome/GWeather4".temperature-unit = "centigrade";

    # Weather app + shell weather widget — Groningen.
    "org/gnome/Weather".locations = [
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "Groningen" "EHGG" true
          [ (mkTuple [ (mkDouble "0.92735160340855627") (mkDouble "0.11490083660519584") ]) ]
          [ (mkTuple [ (mkDouble "0.92886422791138223") (mkDouble "0.11466813185602746") ]) ]
        ]))
      ]))
    ];

    "org/gnome/shell/weather" = {
      automatic-location = false;
      locations = [
        (mkVariant (mkTuple [
          (mkUint32 2)
          (mkVariant (mkTuple [
            "Groningen" "EHGG" true
            [ (mkTuple [ (mkDouble "0.92735160340855627") (mkDouble "0.11490083660519584") ]) ]
            [ (mkTuple [ (mkDouble "0.92886422791138223") (mkDouble "0.11466813185602746") ]) ]
          ]))
        ]))
      ];
    };

    # World clocks — order is positional in the panel UI, not alphabetical.
    "org/gnome/shell/world-clocks".locations = [
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "San Francisco" "KOAK" true
          [ (mkTuple [ (mkDouble "0.65832848982162007") (mkDouble "-2.133408063190589") ]) ]
          [ (mkTuple [ (mkDouble "0.659296885757089") (mkDouble "-2.1366218601153339") ]) ]
        ]))
      ]))
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "New York" "KNYC" true
          [ (mkTuple [ (mkDouble "0.71180344078725644") (mkDouble "-1.2909618758762367") ]) ]
          [ (mkTuple [ (mkDouble "0.71059804659265924") (mkDouble "-1.2916478949920254") ]) ]
        ]))
      ]))
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "London" "EGWU" true
          [ (mkTuple [ (mkDouble "0.89971722940307675") (mkDouble "-0.007272211034407213") ]) ]
          [ (mkTuple [ (mkDouble "0.89884456477707964") (mkDouble "-0.0020362232784242244") ]) ]
        ]))
      ]))
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "Paris" "LFPB" true
          [ (mkTuple [ (mkDouble "0.85462956287765413") (mkDouble "0.042760566673861078") ]) ]
          [ (mkTuple [ (mkDouble "0.8528842336256599") (mkDouble "0.040724343395436846") ]) ]
        ]))
      ]))
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "Berlin" "EDDB" true
          [ (mkTuple [ (mkDouble "0.91426163401859872") (mkDouble "0.23591034304566436") ]) ]
          [ (mkTuple [ (mkDouble "0.91658875132345297") (mkDouble "0.23387411976724018") ]) ]
        ]))
      ]))
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "Moscow" "UUWW" true
          [ (mkTuple [ (mkDouble "0.97127572873484425") (mkDouble "0.65042604039431762") ]) ]
          [ (mkTuple [ (mkDouble "0.97305983920281813") (mkDouble "0.65651530216830811") ]) ]
        ]))
      ]))
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "Hong Kong" "VHHH" true
          [ (mkTuple [ (mkDouble "0.38979019379430269") (mkDouble "1.9928751117510946") ]) ]
          [ (mkTuple [ (mkDouble "0.38949931722116538") (mkDouble "1.9928751117510946") ]) ]
        ]))
      ]))
      (mkVariant (mkTuple [
        (mkUint32 2)
        (mkVariant (mkTuple [
          "Seoul" "RKSS" true
          [ (mkTuple [ (mkDouble "0.65537113412387071") (mkDouble "2.2130774915288098") ]) ]
          [ (mkTuple [ (mkDouble "0.65565717613498009") (mkDouble "2.2165632980174781") ]) ]
        ]))
      ]))
    ];

    # ----------------------------------------------------------------------
    # virt-manager
    # ----------------------------------------------------------------------

    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
