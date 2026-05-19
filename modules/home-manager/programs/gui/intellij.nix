{ config, lib, pkgs, ... }:

# JetBrains IDEs — packages and shared/per-IDE settings.
#
# JetBrains IDE config dirs are versioned (e.g. ~/.config/JetBrains/IdeaIU2024.3).
# Pinning to a specific version means the settings silently stop applying on
# the next major release, so we use an activation script that fan-outs to
# every matching `<Prefix>*` directory under ~/.config/JetBrains/. That makes
# the config robust to version bumps and to multiple installed versions.

let
  # Per-IDE config-dir prefix used by `~/.config/JetBrains/<prefix><version>/`.
  # Add a new entry here when you install another JetBrains IDE.
  idePrefixes = [
    "CLion"
    "GoLand"
    "IdeaIU"     # IntelliJ IDEA Ultimate (use IdeaIC for Community)
    "PhpStorm"
    "PyCharm"    # PyCharm Professional / Community share this prefix
    "Rider"
    "RustRover"
    "WebStorm"
  ];

  # ----------------------------------------------------------------------
  # Shared settings — applied to every IDE listed above.
  # File path is relative to the IDE config dir.
  # ----------------------------------------------------------------------
  sharedSettings = {
    "options/editor.xml" = pkgs.writeText "jb-editor.xml" ''
      <application>
        <component name="EditorSettings">
          <option name="IS_ENSURE_NEWLINE_AT_EOF" value="true" />
          <option name="IS_WHITESPACES_SHOWN" value="true" />
          <option name="IS_INDENT_GUIDES_SHOWN" value="true" />
        </component>
      </application>
    '';

    "options/ide.general.xml" = pkgs.writeText "jb-ide.general.xml" ''
      <application>
        <component name="UISettings">
          <option name="EDITOR_TAB_PLACEMENT" value="4" />
          <option name="EDITOR_TAB_LIMIT" value="100" />
          <option name="MARK_MODIFIED_TABS_WITH_ASTERISK" value="true" />
          <option name="SHOW_CLOSE_BUTTON" value="true" />
        </component>
      </application>
    '';

    "options/editor-font.xml" = pkgs.writeText "jb-editor-font.xml" ''
      <application>
        <component name="EditorSettings">
          <option name="USE_SOFT_WRAPS" value="CONSOLE,MAIN_EDITOR,PREVIEW" />
          <option name="SOFT_WRAP_FILE_MASKS" value="*.md; *.txt; *.rst; *.adoc" />
        </component>
      </application>
    '';
  };

  # ----------------------------------------------------------------------
  # Per-IDE overrides — file path relative to that IDE's config dir.
  # Keys are the IDE prefixes from `idePrefixes` above. Settings here are
  # applied AFTER shared, so an entry that targets the same path overrides
  # the shared one for that IDE only.
  # ----------------------------------------------------------------------
  perIdeSettings = {
    # Example — declare IDEA-only options:
    # IdeaIU = {
    #   "options/editor-something-idea-specific.xml" = pkgs.writeText "..." ''...'';
    # };
  };

  # Build the activation script: copy each settings file into every matching
  # versioned dir for its IDE prefix. `install` creates parent dirs and writes
  # mode 644 (writable by owner so the IDE can rewrite from its UI later).
  mkCopyLine = prefix: relPath: src: ''
    for d in "$HOME/.config/JetBrains/${prefix}"*/; do
      [ -d "$d" ] || continue
      install -Dm644 ${src} "$d${relPath}"
    done
  '';

  sharedLines =
    lib.concatLists (map (prefix:
      lib.mapAttrsToList (relPath: src: mkCopyLine prefix relPath src) sharedSettings
    ) idePrefixes);

  perIdeLines =
    lib.concatLists (lib.mapAttrsToList (prefix: files:
      lib.mapAttrsToList (relPath: src: mkCopyLine prefix relPath src) files
    ) perIdeSettings);
in
{
  home.packages = with pkgs; [
    jetbrains.clion
    jetbrains.goland
    jetbrains.idea           # was idea-ultimate (renamed in nixpkgs)
    jetbrains.phpstorm
    jetbrains.pycharm        # was pycharm-professional (renamed in nixpkgs)
    jetbrains.rider
    jetbrains.rust-rover
    jetbrains.webstorm
  ];

  # Apply settings on every home-manager activation. Robust to version bumps
  # and to multiple installed versions of the same IDE.
  home.activation.jetbrainsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatStringsSep "\n" (sharedLines ++ perIdeLines)
  );

  # ATTENTION: plugins are not declarative on NixOS — install them via the
  # plugin marketplace inside each IDE on first run, or use JetBrains' own
  # Settings Sync (cloud) to mirror across machines. Wishlist:
  #   - Auto Dark Mode
  #   - Better Highlights
  #   - Color Codes / Rainbow Brackets
  #   - Terraform and HCL
  #   - Mermaid
  #   - D2
  #   - Claude (official)
}
