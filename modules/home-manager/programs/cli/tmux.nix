{ ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    # Hold Shift while selecting text to bypass tmux mouse capture.
    extraConfig = ''
      set -g mouse on
    '';
  };
}
