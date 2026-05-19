{ config, pkgs, ... }:

{
  time.timeZone = "Europe/Amsterdam";

  # English UI (messages, menus, app text) with Dutch formatting for
  # dates, numbers, currency, paper sizes, etc. defaultLocale governs
  # LC_MESSAGES + the unset categories; extraLocaleSettings overrides
  # the regional-format categories individually.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_NUMERIC = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_TIME = "nl_NL.UTF-8";
    };
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "nl_NL.UTF-8/UTF-8"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # GPG agent (used for git commit signing). SSH support intentionally off.
  programs.gnupg.agent.enable = true;

  # Stub dynamic linker for generic-Linux binaries (e.g. Node toolchains
  # downloaded by Volta/nvm, prebuilt VS Code extensions, AppImage tools
  # that bypass appimage-run). Without this NixOS refuses to exec them
  # because /lib64/ld-linux-x86-64.so.2 doesn't exist. The library set
  # below covers Node + most common native npm modules.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      openssl
      zlib
    ];
  };

  # iOS device USB connectivity (usbmuxd2 is the maintained fork)
  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };

  environment.systemPackages = with pkgs; [
    # Archive tools
    p7zip
    rar
    unrar
    unzip
    zip

    # Benchmarking & Testing
    stress-ng # System stress testing
    sysbench # System benchmarking

    # Data processing
    jq # JSON processor
    yq-go # YAML processor

    # Development tools
    expect # Scriptable command automation
    flutter # Flutter SDK (Dart + tooling)
    gnumake # `make` — needed outside nix-shell for `make switch` etc.
    man # Manual page reader
    man-pages # Linux man pages collection
    nil # Nix LSP server
    nixpkgs-fmt # Nix formatter
    shellcheck # Shell script linter

    # Editors
    nano

    # File utilities
    bat # cat with syntax highlighting
    eza # Modern ls
    fd # Modern find
    file
    ripgrep # Modern grep (rg)

    # Network tools
    aria2 # Multi-source download manager
    bind # dig, nslookup
    bore-cli # Reverse tunnel / port forwarder
    curl
    gnome-network-displays # Miracast / Chromecast streaming
    magic-wormhole # P2P file transfer
    nmap
    ookla-speedtest
    rsync
    tcpdump
    traceroute
    wget
    whois

    # Process management
    killall
    psmisc

    # Security & Encryption
    age # Modern file encryption
    gnupg # GPG
    openssl
    sops # Secrets management

    # Shell utilities
    bc # Arbitrary-precision calculator
    fzf # Fuzzy finder
    gum # TUI primitives (confirm, choose, input, style) for shell scripts
    powershell
    tldr # TL;DR pages for commands
    tmux # Terminal multiplexer
    wl-clipboard # Wayland clipboard CLI (used by the `clipboard` shell alias)
    zellij # Terminal multiplexer alternative

    # System monitoring and info
    btop # Process monitor with GPU support
    duf # Modern df
    fastfetch # System info display
    glances # Comprehensive system monitor
    htop # Process monitor
    inxi # Detailed system information
    iotop # I/O monitor
    lsof
    ncdu # Disk usage analyzer
    pciutils # lspci
    sysprof # System-wide profiler / tracer
    usbutils # lsusb

    # Version control
    gh # GitHub CLI
    mr # MyRepos - manage multiple repos

    # Fonts
    font-manager

    # Mobile devices (USB file transfer)
    android-tools # ADB / fastboot
    gvfs # GVFS for MTP, GPhoto2, etc.
    ifuse # Mount iOS device filesystems via FUSE
    jmtpfs # Mount Android MTP devices via FUSE
    libimobiledevice # iOS protocol library

    # Use pkgs.unstable.package-name for latest packages
  ];

  users.users.sam = {
    isNormalUser = true;
    description = "Sam";
    extraGroups = [ "audio" "docker" "libvirtd" "networkmanager" "video" "wheel" ];
    initialPassword = "changeme";
    openssh.authorizedKeys.keyFiles = [
      /home/sam/Vault/Keys/Sam/ssh-public.key
    ];
  };

  users.users.sam.hashedPasswordFile = null; # Force password change on first login

  # security.sudo.wheelNeedsPassword = false;
}
