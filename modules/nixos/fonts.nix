{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji # was noto-fonts-emoji
    # noto-fonts-extra  # Merged into noto-fonts (above) in nixpkgs
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "JetBrains Mono" "Noto Sans Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
