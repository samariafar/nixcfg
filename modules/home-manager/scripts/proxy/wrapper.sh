#!/usr/bin/env bash
set -euo pipefail

# Real git binary — substituted by Nix at build time via git.nix
real_git=@REAL_GIT@

# Fast path: not in a git repo (most common for non-git calls)
repo_root=$("$real_git" rev-parse --show-toplevel 2>/dev/null) || {
	exec "$real_git" "$@"
}

# Only intercept proxied repos
origin_url=$("$real_git" config --get remote.origin.url 2>/dev/null || true)

case "$origin_url" in
	file://"${HOME}"/.gitremote/*)
		proxy_dir="${origin_url#file://}"

		case "${1:-}" in
			fetch|pull|push)
				"$real_git" -C "$proxy_dir" fetch real-origin 2>/dev/null || true
				;;
		esac
		;;
esac

exec "$real_git" "$@"
