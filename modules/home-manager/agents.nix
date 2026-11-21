# Wires in the AI assistant config from github:samariafar/agents.
#
# The upstream flake's Home-Manager module owns all the symlinks (it uses
# mkOutOfStoreSymlink against a working tree on disk, so live edits to the
# repo don't need a rebuild). This wrapper just clones that working tree into
# `agents.repoPath` on first activation when it's missing — keeps fresh
# machines from needing a manual `git clone` step.
{ config, lib, pkgs, inputs, ... }:

let
  # `agents-sync` applies the repo's manifests (mcp/servers.json,
  # plugins.json) to each agent's own config. The script runs live from the
  # working tree, so edits to it or to the manifests need no rebuild; Nix
  # only provides the interpreter and the `claude` CLI it shells out to.
  agentsSync = pkgs.writeShellScriptBin "agents-sync" ''
    export PATH=${lib.makeBinPath [ pkgs.unstable.claude-code ]}:$PATH
    exec ${pkgs.python3.withPackages (ps: [ ps.tomlkit ps.ruamel-yaml ])}/bin/python3 \
      "${config.agents.repoPath}/scripts/agents-sync" "$@"
  '';
in
{
  imports = [ inputs.agents.homeManagerModules.default ];

  home.packages = [ agentsSync ];

  # Re-apply global MCP servers to Claude Code / Codex / Gemini / Hermes on
  # every switch, and install any missing Claude plugins. Order after
  # Hermes' own activation is irrelevant: its config merge keeps the
  # `mcp_servers` key this writes. Never fatal: a missing repo checkout or a
  # network hiccup must not abort the switch.
  home.activation.agentsSync =
    lib.hm.dag.entryAfter [ "linkGeneration" "unlockAgentsRepo" ] ''
      if [ -f "${config.agents.repoPath}/scripts/agents-sync" ]; then
        run ${agentsSync}/bin/agents-sync --quiet mcp sync \
          || echo "agents-sync: mcp sync failed (continuing)" >&2
        run ${agentsSync}/bin/agents-sync --quiet plugins sync \
          || echo "agents-sync: plugins sync failed (continuing)" >&2
      fi
    '';

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

  # The upstream module links ~/.claude/settings.json through two Nix-store
  # hops (home-manager-files → hm_settings.json → working tree). Claude Code
  # writes settings atomically by creating a temp file beside the first hop,
  # which lands in the read-only /nix/store and fails with EROFS whenever it
  # updates settings (e.g. `claude plugin install`). Replace that entry with a
  # single direct symlink into the writable working tree.
  home.file.".claude/settings.json".enable = lib.mkForce false;
  home.activation.linkClaudeSettings =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      mkdir -p "$HOME/.claude"
      ln -sfn "${config.agents.repoPath}/settings.json" "$HOME/.claude/settings.json"
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
