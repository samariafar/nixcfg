{ config, pkgs, lib, ... }:

{
  # Flatpak apps (declarative via nix-flatpak). Everything here is packaged as
  # a Flatpak because it is either absent from nixpkgs or broken there.
  #
  # Active:
  # - Denaro: nixpkgs build crashes on .nmoney load (GirCore/.NET binding bug)
  #
  # Disabled — uncomment the matching line in `packages` to restore:
  # - ClamUI: modern GTK4 frontend for ClamAV (not in nixpkgs). ClamAV itself
  #   is disabled too, see modules/nixos/security.nix — re-enable both together.
  # - Convertidor: unit converter (not in nixpkgs)
  # - Defuse: local image background remover (not in nixpkgs)
  # - Sticky Notes: GTK4 sticky-notes app by vixalien (not in nixpkgs)
  # - Tintero: writing studio (not in nixpkgs)
  services.flatpak = {
    enable = true;
    packages = [
      #"app.tintero.Tintero"
      #"com.vixalien.sticky"
      #"io.github.linx_systems.ClamUI"
      #"io.github.shonebinu.Defuse"
      "org.nickvision.money"
      #"tech.digiroad.Convertidor"
    ];
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
  };
}
