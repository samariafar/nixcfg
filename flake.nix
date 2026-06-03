{
  description = "NixOS Configuration with Home Manager";

  inputs = {
    # NixOS 25.11 stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Nixpkgs unstable for latest packages
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager (matching NixOS 25.11)
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Encrypted secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository (used for Firefox addons via rycee.firefox-addons)
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Personal AI assistant config (Claude Code, Codex CLI, Gemini CLI). The
    # flake exposes a Home-Manager module that symlinks files from a working
    # tree on disk (default ~/.agents) into the assistants' dotfile dirs.
    # nixcfg's wrapper at modules/home-manager/agents.nix imports that module
    # and clones the repo on first activation if the path is missing.
    # Private repo — use SSH so Nix authenticates with the user's key instead
    # of GitHub's unauthenticated HTTPS API (which 404s on private repos).
    agents.url = "git+ssh://git@github.com/samariafar/agents.git";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nix-flatpak, sops-nix, nur, ... }@inputs:
    let
      system = "x86_64-linux";

      # Overlay to access unstable packages
      overlays = [
        (final: prev: {
          unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        })
        nur.overlays.default
        (import ./overlays/claudebar.nix)
        (import ./overlays/duplicati-gui.nix)
      ];
    in
    {
      nixosConfigurations = {
        # Workstation configuration
        # Usage: nixos-rebuild switch --sudo --flake ~/.nixcfg#workstation
        workstation = nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs;
            inherit (inputs) nixpkgs-unstable;
          };

          modules = [
            # Apply overlays
            { nixpkgs.overlays = overlays; }

            # Main configuration
            ./hosts/workstation/configuration.nix

            # Flatpak (declarative)
            nix-flatpak.nixosModules.nix-flatpak

            # Encrypted secrets
            sops-nix.nixosModules.sops

            # NUR module (exposes pkgs.nur.repos.*)
            nur.modules.nixos.default

            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # Rename pre-existing files that home-manager wants to manage
              # (e.g. ~/.config/user-dirs.dirs created by GNOME on first boot)
              # rather than aborting with "would be clobbered".
              home-manager.backupFileExtension = "hm-bak";
              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit (inputs) nixpkgs-unstable;
              };
              home-manager.users.sam = import ./users/sam/home.nix;
            }
          ];
        };
      };
    };
}
