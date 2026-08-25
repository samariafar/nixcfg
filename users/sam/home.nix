{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home-manager/agents.nix
    ../../modules/home-manager/dconf.nix
    ../../modules/home-manager/default-apps.nix
    ../../modules/home-manager/editorconfig.nix
    ../../modules/home-manager/shell.nix
    ../../modules/home-manager/programs/cli/direnv.nix
    ../../modules/home-manager/programs/cli/git.nix
    ../../modules/home-manager/programs/cli/ssh.nix
    ../../modules/home-manager/programs/cli/tmux.nix
    #../../modules/home-manager/programs/gui/duplicati.nix
    ../../modules/home-manager/programs/gui/firefox.nix
    #../../modules/home-manager/programs/gui/intellij.nix
    #../../modules/home-manager/programs/gui/thunderbird.nix
    ../../modules/home-manager/programs/gui/zed.nix
  ];

  home = {
    username = "sam";
    homeDirectory = "/home/sam";

    stateVersion = "25.11"; # WARNING: DO NOT CHANGE after initial setup

    packages = with pkgs; [
      # Use pkgs.unstable.package-name for latest packages
      #
      # ATTENTION: Language SDKs / package managers (poetry, uv, rustup, go,
      # bun, pnpm, volta, …) are kept globally for convenience while the
      # repo migrates to per-project envs. End-state: each project ships its
      # own flake.nix or shell.nix and is auto-loaded via direnv (see
      # modules/home-manager/programs/cli/direnv.nix), so the global copies
      # can be removed. Until then, treat the toolchain entries below as
      # transitional — drop them as projects gain their own dev shells.
      #android-studio
      #blanket
      #bruno
      bun
      #chromium
      #cinny-desktop
      cryptomator
      curtail
      #denaro  # Switched to Flathub `org.nickvision.money` — nixpkgs build
               # (2024.2.0) crashes loading .nmoney files due to GirCore/.NET ↔ system
               # GTK4 ABI mismatch; Flatpak bundles its own runtime and dodges it.
      #etcher  # Removed from nixpkgs (Electron app, unmaintained). Install
               # via AppImage from etcher.balena.io, or use Flathub `io.balena.etcher`.
      eyedropper
      #freecad
      #gcolor3  # Switched back to Eyedropper; kept commented as fallback.
      #gitkraken
      gnome-decoder
      #gnome-obfuscate  # Switched back to Gradia; kept commented as fallback.
      go
      gradia
      #imhex
      inkscape
      #kicad
      krita
      #libreoffice
      metadata-cleaner
      #mission-center  # Switched to Resources
      newsflash
      #obs-studio
      #pika-backup
      #planify
      pnpm
      poetry
      # protonmail-bridge-gui — GUI variant. The headless `protonmail-bridge`
      # package can be paired with `services.protonmail-bridge.enable` for a
      # system-managed daemon, but we want user-level here.
      #protonmail-bridge-gui
      raider
      remmina
      resources
      # RustDesk client (Flutter UI is the modern build; legacy Sciter UI is
      # still available as `rustdesk`). NixOS module `services.rustdesk-server`
      # exists for the relay/server side — intentionally not enabled here.
      #rustdesk-flutter
      rustup
      #sourcegit
      # TeamViewer client. Connections require teamviewerd; we leave
      # `services.teamviewer.enable` off (user request) so launch the daemon
      # manually with `sudo systemctl start teamviewerd` only when needed.
      #teamviewer
      #textpieces
      uv
      #video-trimmer
      #vlc
      volta
      warp
    ] ++ (with pkgs.unstable; [
      claude-code
      #codex
      #gemini-cli
      #lmstudio
      # obsidian on stable (1.10.3) pins EOL electron_40; unstable (1.12.7+) uses electron_41.
      #obsidian
      opencode
      #winboat
    ]) ++ (with pkgs.nodePackages; [
      npm-check-updates
    ]);

    sessionVariables = {
      EDITOR = "nano";
      VISUAL = "nano";
      VOLTA_HOME = "${config.home.homeDirectory}/.volta";
    };

    # Volta-managed Node shims (npm globals installed via `volta install`).
    sessionPath = [ "${config.home.homeDirectory}/.volta/bin" ];

    # Ensure custom top-level directories exist on activation. Safe to re-run
    # — `mkdir -p` skips paths that already exist.
    activation.createDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME"/{Projects,Scripts,Vault}
    '';
  };

  # Custom XCompose key shortcuts. Lives at ~/.XCompose (the canonical
  # path libX11/libxkbcommon look at) so GNOME on both X11 and Wayland
  # honours it. Compose key is set to Right-Alt in input-sources.
  home.file.".XCompose".source = ./files/xcompose;

  # Mute the GNOME screenshot tool's shutter. libcanberra resolves each sound
  # file by walking XDG_DATA_DIRS (XDG_DATA_HOME first), so a zero-byte
  # `screen-capture.oga` here shadows just that one event from the system
  # `freedesktop` theme — every other sound still plays normally.
  home.file.".local/share/sounds/freedesktop/stereo/screen-capture.oga".text = "";

  # Standard XDG user directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # Nautilus / GTK file manager bookmarks (left sidebar)
  gtk = {
    enable = true;
    gtk3.bookmarks = [
      "file:///home/sam/Desktop Desktop"
      "file:///home/sam/Downloads Downloads"
      "file:///home/sam/Documents Documents"
      "file:///home/sam/Pictures Pictures"
      "file:///home/sam/Projects Projects"
      "file:///home/sam/Vault Vault"
    ];
  };

  # Add personal font collection (~/Fonts) to fontconfig search paths
  xdg.configFile."fontconfig/conf.d/10-personal-fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <dir>${config.home.homeDirectory}/Fonts</dir>
    </fontconfig>
  '';

  programs.home-manager.enable = true;
}
