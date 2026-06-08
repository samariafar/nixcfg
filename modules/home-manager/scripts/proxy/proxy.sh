# Proxy subcommands for `git()` — sourced by git.sh from ~/.config/git/proxy.sh.
# Declared in git.nix as home.file.".config/git/proxy.sh".

__git_proxy_setup() {
	local repo_root real_url hash proxy_dir current_origin

	repo_root=$(command git rev-parse --show-toplevel 2>/dev/null) || {
		echo "Error: not inside a git repository." >&2
		return 1
	}

	current_origin=$(command git config --get remote.origin.url 2>/dev/null || true)

	if [[ "$current_origin" == file://"${HOME}"/.gitremote/* ]]; then
		echo "Error: already proxied (origin = $current_origin)" >&2
		echo "Run 'git proxy remove' first." >&2
		return 1
	fi

	if [[ -n "${1:-}" ]]; then
		real_url="$1"
	elif [[ -n "$current_origin" ]]; then
		real_url="$current_origin"
	else
		echo "Error: no remote origin and no URL provided." >&2
		echo "Usage: git proxy setup [<remote-url>]" >&2
		return 1
	fi

	hash=$(printf '%s' "$real_url" | sha256sum | cut -c1-12)
	proxy_dir="${HOME}/.gitremote/${hash}"

	if [[ ! -d "$proxy_dir" ]]; then
		command git init --bare "$proxy_dir"
		command git -C "$proxy_dir" config remote.real-origin.url "$real_url"

		cat > "$proxy_dir/hooks/post-receive" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
command git push --mirror real-origin
HOOK
		chmod +x "$proxy_dir/hooks/post-receive"
	fi

	if [[ -n "$current_origin" ]]; then
		command git remote remove origin
	fi
	command git remote add origin "file://${proxy_dir}"

	command git push --all origin
	command git push --tags origin 2>/dev/null || true

	gum style --foreground 212 "Proxy set up for ${real_url}"
	gum style --foreground 244 "  origin -> file://${proxy_dir}"
}

__git_proxy_remove() {
	local repo_root current_origin hash proxy_dir real_url

	repo_root=$(command git rev-parse --show-toplevel 2>/dev/null) || {
		echo "Error: not inside a git repository." >&2
		return 1
	}

	current_origin=$(command git config --get remote.origin.url 2>/dev/null || true)

	if [[ "$current_origin" != file://"${HOME}"/.gitremote/* ]]; then
		echo "Error: not a proxied repo (origin = $current_origin)" >&2
		return 1
	fi

	proxy_dir="${current_origin#file://}"
	hash=$(basename "$proxy_dir")
	real_url=$(command git -C "$proxy_dir" config --get remote.real-origin.url 2>/dev/null || true)

	if [[ -z "$real_url" ]]; then
		echo "Error: bare repo at $proxy_dir has no real-origin URL" >&2
		return 1
	fi

	command git remote remove origin
	command git remote add origin "$real_url"
	command git fetch origin --all 2>/dev/null || true

	gum style --foreground 212 "Proxy removed. Origin restored to ${real_url}"
	gum style --foreground 244 "  Bare repo kept at ~/.gitremote/${hash}"
	echo "  Remove it manually or run: rm -rf ~/.gitremote/${hash}"
}

__git_proxy_status() {
	local repo_root current_origin hash proxy_dir real_url

	repo_root=$(command git rev-parse --show-toplevel 2>/dev/null) || {
		echo "Not inside a git repository."
		return 0
	}

	current_origin=$(command git config --get remote.origin.url 2>/dev/null || true)

	if [[ "$current_origin" == file://"${HOME}"/.gitremote/* ]]; then
		proxy_dir="${current_origin#file://}"
		real_url=$(command git -C "$proxy_dir" config --get remote.real-origin.url 2>/dev/null || echo "unknown")
		hash=$(basename "$proxy_dir")
		gum style --foreground 212 "Proxy active"
		gum style --foreground 244 "  repo      : $(basename "$repo_root")"
		gum style --foreground 244 "  origin    : file://.../${hash}"
		gum style --foreground 244 "  real URL  : ${real_url}"
	else
		gum style --foreground 244 "No proxy active"
		[[ -n "$current_origin" ]] && gum style --foreground 244 "  origin : $current_origin"
	fi
}

__git_proxy_sync() {
	local count=0 proxy_dir real_url

	for proxy_dir in "${HOME}"/.gitremote/*/; do
		[[ -d "$proxy_dir" ]] || continue
		real_url=$(command git -C "$proxy_dir" config --get remote.real-origin.url 2>/dev/null || true)
		if [[ -n "$real_url" ]]; then
			hash=$(basename "$proxy_dir")
			gum style --foreground 244 "  [${hash}] fetching from ${real_url} ..."
			command git -C "$proxy_dir" fetch real-origin 2>&1 | sed 's/^/    /'
			count=$((count + 1))
		fi
	done

	if (( count == 0 )); then
		gum style --foreground 244 "No proxies found in ~/.gitremote/"
	else
		gum style --foreground 212 "Synced ${count} prox(ies)."
	fi
}
