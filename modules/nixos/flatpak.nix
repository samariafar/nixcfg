{ config, pkgs, lib, ... }:

{
  # Flatpak apps (declarative via nix-flatpak):
  # - ClamUI: modern GTK4 frontend for ClamAV (not in nixpkgs)
  # - Convertidor: unit converter (not in nixpkgs)
  # - Denaro: nixpkgs build crashes on .nmoney load (GirCore/.NET binding bug)
  # - Tintero: writing studio (not in nixpkgs)
  services.flatpak = {
    enable = true;
    packages = [
      "app.tintero.Tintero"
      "io.github.linx_systems.ClamUI"
      "org.nickvision.money"
      "tech.digiroad.Convertidor"
    ];
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
  };
}
