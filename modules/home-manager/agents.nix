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
}
