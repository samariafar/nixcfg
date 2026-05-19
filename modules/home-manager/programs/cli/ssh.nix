{ config, lib, pkgs, ... }:

let
  artifexKey = "${config.home.homeDirectory}/Vault/Keys/Artifex/ssh-private.key";
  samKey = "${config.home.homeDirectory}/Vault/Keys/Sam/ssh-private.key";
in
{
  # Seed ~/.ssh/known_hosts with host-key entries for our SSH aliases.
  # GitKraken (libgit2/libssh2) reads ~/.ssh/known_hosts directly and ignores
  # HostKeyAlias from ssh_config, so aliases must appear literally in the file.
  home.activation.seedKnownHosts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    KH="$HOME/.ssh/known_hosts"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$KH"
    chmod 600 "$KH"

    seed() {
      upstream="$1"
      aliases="$2"
      marker="$3"
      if ! grep -q "^$marker[, ]" "$KH"; then
        if scan=$(${pkgs.openssh}/bin/ssh-keyscan "$upstream" 2>/dev/null); then
          echo "$scan" | sed "s|^$upstream|$aliases|" >> "$KH"
        fi
      fi
    }

    seed github.com "artifex.github.com,github.com" artifex.github.com
    seed gitlab.com "artifex.gitlab.com,gitlab.com" artifex.gitlab.com
  '';

  programs.ssh = {
    enable = true;

    # home-manager 25.11 deprecates the implicit defaults under programs.ssh.
    # Opt out and re-declare any defaults we want under matchBlocks."*".
    enableDefaultConfig = false;

    # Default identity is the Sam key; artifex.* aliases route to the Artifex key.
    matchBlocks = {
      "*" = {
        identityFile = samKey;
      };

      "gitlab.alpinelinux.org" = {
        identityFile = artifexKey;
      };

      # Aliases that resolve to real hosts but use the Artifex key.
      # Usage: git clone git@artifex.github.com:org/repo.git
      "artifex.github.com" = {
        hostname = "github.com";
        identityFile = artifexKey;
        extraOptions.HostKeyAlias = "github.com";
      };

      "artifex.gitlab.com" = {
        hostname = "gitlab.com";
        identityFile = artifexKey;
        extraOptions.HostKeyAlias = "gitlab.com";
      };
    };
  };
}
