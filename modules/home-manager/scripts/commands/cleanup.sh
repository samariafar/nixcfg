cleanup() {
	nix-collect-garbage --delete-old
	sudo nix-collect-garbage --delete-old
	docker system prune --all --volumes --force
}
