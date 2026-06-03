{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableVteIntegration = true;

    historySize = 10000;        # per session
    historyFileSize = 100000;   # across all sessions
    historyControl = [ "ignoreboth" ];
    historyIgnore = [
      "clear"
      "exit"
      "history"
      "htop"
      "man"
      "tmux"
      "zellij"
    ];

    shellOptions = [
      "checkjobs"
      "checkwinsize"
      "cmdhist"
      "dotglob"
      "extglob"
      "globstar"
      "histappend"
      "lithist"
      "nocaseglob"
    ];

    sessionVariables = {
      DIRENV_LOG_FORMAT = "";                      # silence direnv chatter
      HISTTIMEFORMAT = "[%F %T]  ";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/Vault/Keys/Sam/age-private.key";
    };

    shellAliases = {
      ".." = "cd ..";
      artisan = "php artisan";
      clipboard = "wl-copy";
      con = "warp-cli connect";
      dis = "warp-cli disconnect";
      dockers = "docker ps --format 'table {{ .ID }}\t{{.Names}}\t{{.Status}}'";
      hog = "ncdu /";
      htop = "htop -t";
      ll = "eza -lah --git --time-style=long-iso --group-directories-first";
      ls = "eza";
      nix-info = "nix-info -m";
      open = "xdg-open";
      python = "python3";
      rebuild = "nixos-rebuild switch --sudo --flake ~/.nixcfg#workstation";
      sail = "./vendor/bin/sail";
      tree = "eza --tree -lah --git --time-style=long-iso --ignore-glob='.git|node_modules'";
      zed = "zeditor";
    };
    initExtra = ''
    	# Re-source ~/.profile so changes to home.sessionVariables /
    	# home.sessionPath reach interactive non-login shells without a
    	# logout/login cycle. hm-session-vars.sh self-guards via
    	# $__HM_SESS_VARS_SOURCED, which is inherited from gnome-shell —
    	# so unset it first to force re-evaluation against the *current*
    	# generation rather than whatever was active at GDM login.
    	unset __HM_SESS_VARS_SOURCED
    	[ -f "$HOME/.profile" ] && . "$HOME/.profile"

    	# Load custom commands
    	for script in ${./scripts/commands}/*.sh; do
    		[ -f "$script" ] && source "$script"
    	done

    	# Load command overrides
    	for script in ${./scripts/overrides}/*.sh; do
    		[ -f "$script" ] && source "$script"
    	done

    	# Newline-preserver (zsh PROMPT_SP equivalent) + cross-session history sync.
    	# When previous output lacks a trailing \n, prints an inverse-video % marker and
    	# forces the prompt onto a fresh line; invisible otherwise.
    	# Set here (not in sessionVariables) because the value contains double quotes.
    	PROMPT_COMMAND='printf "\033[7m%%\033[0m%*s\r\033[K" "$((COLUMNS-1))" ""; history -a; history -n'
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = "$username$hostname$directory$git_branch$git_commit$git_state$git_status$cmd_duration$character";

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      username = {
        show_always = true;
        format = "[$user]($style)";
        style_user = "bold cyan";
        style_root = "bold red";
      };

      hostname = {
        ssh_only = false;
        format = "@[$hostname]($style) ";
        style = "bold cyan";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        symbol = " ";
      };

      git_status = {
        conflicted = "🏳";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        up_to_date = "✓";
        untracked = "?";
        stashed = "\\$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      cmd_duration = {
        min_time = 2000;
        format = "took [$duration](bold yellow)";
      };
    };
  };
}
