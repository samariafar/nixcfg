{ config, pkgs, osConfig, ... }:

let
  profiles = {
    sam = {
      name = "Sam Ariafar";
      email = "me@samariafar.com";
      signingkey = "43980348B058F190C95BD47F8412223052412037";
      sshKey = "~/Vault/Keys/Sam/ssh-private.key";
      emoji = "😃";
    };
    artifex = {
      # name, email, signingkey are sops-encrypted and rendered at activation
      # time into the templates declared in modules/nixos/secrets.nix
      # (`git-config-artifex` and `git-profiles-artifex`). They are
      # consumed below via osConfig.sops.templates.<name>.path — never inlined
      # at Nix evaluation, so they don't leak into the Nix store or the repo.
      sshKey = "~/Vault/Keys/Artifex/ssh-private.key";
      emoji = "😎";
    };
  };
in
{
  # ~/.local/bin/git (the wrapper) must shadow the Nix-profile git on PATH.
  home.sessionPath = [ "~/.local/bin" ];

  # NOTE: home-manager 25.11 collapsed programs.git's per-key options
  # (userName, userEmail, aliases, extraConfig) into a single
  # `programs.git.settings` INI attrset. Delta moved to `programs.delta`.

  programs.git = {
    enable = true;

    signing = {
      key = profiles.sam.signingkey;
      signByDefault = true;
    };

    ignores = [
      ".claude/"
      ".direnv/"
      ".DS_Store"
      ".idea/"
      ".vscode/"
      "*.sw?"
      "*~"
      "desktop.ini"
      "node_modules/"
      "Thumbs.db"
    ];

    settings = {
      user = {
        name = profiles.sam.name;
        email = profiles.sam.email;
      };

      # NOTE: Custom git subcommands (last, log, profile, unstage, untrack)
      # live in scripts/overrides/git.sh as shell-function cases — single
      # place for all customizations. Profile data is sourced from
      # ~/.config/git/profiles.sh, generated below from the `let profiles = …`
      # binding at the top of this file (single source of truth).

      core = {
        autocrlf = false;
        editor = "nano";
        filemode = false;
        ignorecase = false;
        sshCommand = "ssh -i ${profiles.sam.sshKey}";
        symlinks = false;
      };

      init.defaultBranch = "main";
      pull.rebase = false;

      commit.gpgsign = true;
      gpg.program = "gpg2";

      tag = {
        forceSignAnnotated = true;
        gpgsign = true;
      };

      rerere.enabled = true;

      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      diff.colorMoved = "default";
      merge.conflictstyle = "diff3";
      rebase.autoStash = true;

      # Auto-convert HTTPS to SSH
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";
      # TODO: Add Gitea URL rewriting when domain is known

      # The artifex profile for ~/Projects/Public/
      includeIf."gitdir:~/Projects/Public/" = {
        path = "~/.config/git/config-artifex";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "side-by-side line-numbers decorations";
      syntax-theme = "Dracula";
      navigate = true;
      light = false;
    };
  };

  # Symlink the sops-rendered artifex git config into the user's home so
  # the includeIf rule above resolves. The target lives at
  # /run/secrets-rendered/git-config-artifex and is rewritten on each
  # activation; mkOutOfStoreSymlink avoids home-manager trying to copy it
  # into the Nix store at build time.
  home.file.".config/git/config-artifex".source =
    config.lib.file.mkOutOfStoreSymlink
      osConfig.sops.templates."git-config-artifex".path;

  # Profile data for `git profile` (implemented in scripts/overrides/git.sh).
  # Sourced at shell startup; updates apply on next shell after rebuild.
  # Artifex-profile values (name/email/signingkey) come from the
  # sops-rendered env file so they never enter the Nix store.
  home.file.".config/git/profiles.sh".text = ''
    source ${osConfig.sops.templates."git-profiles-artifex".path}
    declare -A PROFILE_NAME=(
      [sam]='${profiles.sam.name}'
      [artifex]="$PROFILE_ARTIFEX_NAME"
    )
    declare -A PROFILE_EMAIL=(
      [sam]='${profiles.sam.email}'
      [artifex]="$PROFILE_ARTIFEX_EMAIL"
    )
    declare -A PROFILE_SIGNINGKEY=(
      [sam]='${profiles.sam.signingkey}'
      [artifex]="$PROFILE_ARTIFEX_SIGNINGKEY"
    )
    declare -A PROFILE_SSHKEY=(
      [sam]='${profiles.sam.sshKey}'
      [artifex]='${profiles.artifex.sshKey}'
    )
    declare -A PROFILE_EMOJI=(
      [sam]='${profiles.sam.emoji}'
      [artifex]='${profiles.artifex.emoji}'
    )
    VALID_PROFILES=(sam artifex)
  '';

  # Proxy subcommands — sourced by git.sh's git() override
  home.file.".config/git/proxy.sh".source = ../../scripts/proxy/proxy.sh;

  # Git wrapper on PATH — syncs proxy bare repos before fetch/pull/push so
  # that tools using libgit2 (e.g. GitKraken) transparently get fresh data
  # from the real remote without ever seeing its URL.
  home.file."bin/git" = {
    text = builtins.replaceStrings
      [ "@REAL_GIT@" ]
      [ "${pkgs.git}/bin/git" ]
      (builtins.readFile ../../scripts/proxy/wrapper.sh);
    executable = true;
  };
}
