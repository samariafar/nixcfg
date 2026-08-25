{ ... }:

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Documents
      "application/pdf" = "org.gnome.Evince.desktop";
      "text/plain" = "org.gnome.TextEditor.desktop";

      # Markdown — handled by MD Reader Firefox addon
      "text/markdown" = "firefox.desktop";

      # Web
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";

      # E-Mails — Thunderbird is disabled (see users/sam/home.nix), so mail
      # falls through to Firefox and whatever webmail handler it registers.
      # ATTENTION: Firefox has no real .eml viewer; `message/rfc822` will just
      # render the raw message source. Restore the Thunderbird lines below
      # alongside the home.nix import if that becomes annoying.
      #"message/rfc822" = "thunderbird.desktop";
      #"x-scheme-handler/mailto" = "thunderbird.desktop";
      "message/rfc822" = "firefox.desktop";
      "x-scheme-handler/mailto" = "firefox.desktop";
    };
  };
}
