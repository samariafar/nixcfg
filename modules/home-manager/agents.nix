# Wires in the AI assistant config from github:samariafar/agents.
#
# The upstream flake's Home-Manager module owns all the symlinks (it uses
# mkOutOfStoreSymlink against a working tree on disk, so live edits to the
# repo don't need a rebuild). This wrapper just clones that working tree into
# `agents.repoPath` on first activation when it's missing — keeps fresh
# machines from needing a manual `git clone` step.
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.agents.homeManagerModules.default ];

  home.activation.cloneAgentsRepo =
    lib.hm.dag.entryBefore [ "agentsRepoCheck" ] ''
      if [ ! -d "${config.agents.repoPath}" ]; then
        echo "agents: cloning samariafar/agents into ${config.agents.repoPath}"
        ${pkgs.git}/bin/git clone \
          git@github.com:samariafar/agents.git \
          "${config.agents.repoPath}" || \
          echo "agents: clone failed — symlinks will dangle until ${config.agents.repoPath} exists (SSH auth to github.com required)" >&2
      fi
    '';

  # The git-crypt symmetric key lives inside the repo at secrets.yaml as
  # the base64-encoded value `git_crypt_key`, encrypted with the user's
  # age key. On a fresh clone the working tree is encrypted gibberish
  # until `git-crypt unlock` is run; this hook extracts and decodes the
  # key via sops and unlocks the repo automatically, so bootstrap is just
  # `clone → rebuild`.
  #
  # Lock-state probe: presence of .git/git-crypt/keys/default — git-crypt
  # writes the unlocked symmetric key there on a successful unlock, and
  # nothing else creates that path. A magic-bytes probe (grep for the
  # \0GITCRYPT\0 header in an encrypted file) does NOT work, because
  # process argv is NUL-terminated — bash's $'\x00…' would arrive at
  # grep as an empty string and match every file.
  home.activation.unlockAgentsRepo =
    lib.hm.dag.entryBetween [ "agentsRepoCheck" ] [ "cloneAgentsRepo" ] ''
      repo="${config.agents.repoPath}"
      keysrc="$repo/secrets.yaml"
      if [ -d "$repo/.git" ] \
         && [ -f "$keysrc" ] \
         && [ ! -f "$repo/.git/git-crypt/keys/default" ]; then
        echo "agents: unlocking git-crypt working tree at $repo"
        tmp=$(${pkgs.coreutils}/bin/mktemp)
        ${pkgs.sops}/bin/sops --decrypt --extract '["git_crypt_key"]' \
          "$keysrc" | ${pkgs.coreutils}/bin/base64 -d > "$tmp"
        ( cd "$repo" && ${pkgs.git-crypt}/bin/git-crypt unlock "$tmp" )
        ${pkgs.coreutils}/bin/rm -f "$tmp"
      fi
    '';
}
