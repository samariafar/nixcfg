upgrade() {
	cd ~/.nixcfg
	nix flake update
	sudo nixos-rebuild boot --flake .#workstation
}
