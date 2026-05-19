{ ... }:

{
  # Run AppImages directly. `binfmt = true` registers a kernel handler so
  # `./Foo.AppImage` Just Works without explicit appimage-run wrapping.
  #
  # ATTENTION: NixOS does not have an AppImageLauncher equivalent (no GUI to
  # auto-integrate desktop entries). To register .AppImage files as launcher
  # icons, drop a .desktop file into ~/.local/share/applications/ manually,
  # or run the AppImage once and rely on its self-integration if it offers
  # one.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
