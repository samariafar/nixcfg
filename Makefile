# NixOS Configuration Makefile

# Special targets
.ONESHELL:
.DELETE_ON_ERROR:
.SHELLFLAGS := -eu -o pipefail -c

# Silent by default — set DEBUG=true to echo each command before running it
ifneq ($(DEBUG),true)
.SILENT:
endif

# Declare phony targets
.PHONY: help init install switch test boot update upgrade clean gc show fmt check copy-hardware \
        scan audit 2fa ssh-keygen claudebar-update logs generations rollback

# Default configuration name
CONFIG ?= workstation

# Installation path on target system (override on the command line if needed)
INSTALL_PATH ?= $(HOME)/.nixcfg

# Path to flake (use current directory)
FLAKE := .

# Default shell
SHELL := bash

# Default target
.DEFAULT_GOAL := help

# Help command - shows all available targets
help:
	cat <<-EOF
	NixOS Configuration Management

	Setup & Deployment:
	  make init            - Initialize flake.lock (first time setup)
	  make install         - Copy configuration to $(INSTALL_PATH)
	  make copy-hardware   - Copy hardware-configuration.nix from /etc/nixos

	System Management:
	  make switch          - Build and activate configuration
	  make test            - Test configuration without making it persistent
	  make boot            - Set configuration for next boot

	Updates & Maintenance:
	  make update          - Update flake inputs
	  make upgrade         - Update inputs and rebuild system
	  make clean           - Remove old generations (7+ days)
	  make gc              - Run garbage collection

	Development:
	  make show            - Show flake info and system generations
	  make fmt             - Format Nix files
	  make check           - Check flake for errors

	Security:
	  make scan PATH=...   - ClamAV scan a path (default: ~/Downloads)
	  make audit           - Run lynis security audit
	  make 2fa             - Set up TOTP 2FA (run before enabling SSH)
	  make ssh-keygen      - Generate ed25519 SSH keypair

	System:
	  make logs            - Tail systemd journal
	  make generations     - List system generations
	  make rollback        - Rollback to previous generation

	Maintenance:
	  make claudebar-update [VER=x.y.z] - Update ClaudeBar (auto-discovers latest; VER pins a specific version)

	Configuration: $(CONFIG)
	Install Path: $(INSTALL_PATH)
	EOF

# Initialize flake (first time setup)
init:
	echo "Initializing flake..."
	nix flake update
	echo "Flake initialized successfully!"

# Install configuration to target path
install:
	cat <<-EOF
	Installing configuration to $(INSTALL_PATH)...
	EOF
	if [ -d "$(INSTALL_PATH)" ]; then
		cat <<-EOF
		ERROR: Directory $(INSTALL_PATH) already exists.
		Remove it first or use a different path.
		EOF
		exit 1
	fi
	mkdir -p $(INSTALL_PATH)
	cp -r . $(INSTALL_PATH)
	cat <<-EOF
	Configuration installed to $(INSTALL_PATH)

	Next steps:
	  1. cd $(INSTALL_PATH)
	  2. make copy-hardware
	  3. make switch
	EOF

# Copy hardware configuration from /etc/nixos
copy-hardware:
	echo "Copying hardware configuration..."
	if [ ! -f /etc/nixos/hardware-configuration.nix ]; then
		cat <<-EOF
		ERROR: /etc/nixos/hardware-configuration.nix not found!
		Generate it first with: nixos-generate-config
		EOF
		exit 1
	fi
	cp /etc/nixos/hardware-configuration.nix hosts/$(CONFIG)/
	cat <<-EOF
	Hardware configuration copied to hosts/$(CONFIG)/hardware-configuration.nix
	Don't forget to uncomment the import in hosts/$(CONFIG)/configuration.nix
	EOF

# Build and activate configuration
switch:
	sudo nixos-rebuild switch --flake $(FLAKE)#$(CONFIG)
	if [ -n "$${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v gnome-extensions >/dev/null; then
		gnome-extensions disable nightthemeswitcher@romainvigier.fr
		gnome-extensions enable nightthemeswitcher@romainvigier.fr
	fi

# Build and activate configuration (test mode - not persistent across reboots)
test:
	sudo nixos-rebuild test --flake $(FLAKE)#$(CONFIG)

# Build configuration and set as default for next boot (doesn't activate now)
boot:
	sudo nixos-rebuild boot --flake $(FLAKE)#$(CONFIG)

# Update flake inputs
update:
	nix flake update

# Update flake inputs and rebuild system
upgrade: update switch

# Clean old system generations (keeps last 7 days)
clean:
	sudo nix-collect-garbage --delete-older-than 7d

# Run garbage collection to free up disk space
gc:
	sudo nix-collect-garbage -d
	nix-store --optimise

# Show flake metadata and outputs
show:
	nix flake show
	echo ""
	echo "Current system generation:"
	sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -5

# Format all Nix files
fmt:
	nixpkgs-fmt .

# Check flake for errors
check:
	nix flake check

# Security: ClamAV scan (defaults to ~/Downloads, override with PATH=...)
SCAN_PATH ?= ~/Downloads
scan:
	clamscan -r --bell -i $(SCAN_PATH)

# Security: Run lynis security audit
audit:
	sudo lynis audit system

# Security: Set up TOTP 2FA (run BEFORE enabling SSH)
2fa:
	cat <<-EOF
	Setting up TOTP 2FA. Recommended answers:
	  - Time-based tokens? Yes
	  - Update ~/.google_authenticator? Yes
	  - Disallow multiple uses? Yes
	  - Increase window for time skew? No
	  - Rate limiting? Yes

	IMPORTANT: Save the QR code, secret key, and 5 emergency scratch codes!
	EOF
	google-authenticator

# Generate ed25519 SSH keypair
ssh-keygen:
	cat <<-EOF
	Generating ed25519 SSH keypair...
	EOF
	read -p "Email/comment for the key: " email
	ssh-keygen -t ed25519 -C "$$email"

# Update ClaudeBar overlay (auto-discovers latest GitHub release;
# pass VER=x.y.z to pin a specific version. If discovery fails — e.g. no
# network or GitHub API down — the currently pinned version is kept.)
claudebar-update:
	OVERLAY=overlays/claudebar.nix
	CURRENT=$$(grep -oP 'version = "\K[^"]+' $$OVERLAY)
	if [ -n "$(VER)" ]; then
		TARGET="$(VER)"
		echo "Using user-supplied version: $$TARGET"
	else
		echo "Discovering latest release from github.com/bilbilak/claudebar..."
		TAG=$$(curl -fsSL https://api.github.com/repos/bilbilak/claudebar/releases/latest 2>/dev/null | jq -r '.tag_name // empty' 2>/dev/null || true)
		if [ -z "$$TAG" ]; then
			echo "WARNING: Could not reach GitHub (network/API issue or rate limit)."
			echo "Keeping currently pinned version: $$CURRENT (no changes made)."
			echo "To force a specific version: make claudebar-update VER=x.y.z"
			exit 0
		fi
		TARGET="$${TAG#v}"
		echo "Latest release: $$TAG (version $$TARGET)"
	fi
	if [ "$$TARGET" = "$$CURRENT" ]; then
		echo "Already at version $$TARGET — nothing to do."
		exit 0
	fi
	echo "Prefetching release zip and computing SRI hash..."
	HASH=$$(nix-prefetch-url --unpack "https://github.com/bilbilak/claudebar/releases/download/v$$TARGET/claudebar-linux-gnome-v$$TARGET.zip")
	SRI=$$(nix-hash --to-sri --type sha256 $$HASH)
	sed -i -E "s|version = \"[^\"]*\";|version = \"$$TARGET\";|" $$OVERLAY
	sed -i -E "s|hash = \"sha256-[^\"]*\";|hash = \"$$SRI\";|" $$OVERLAY
	cat <<-EOF
	Updated $$OVERLAY:
	  version: $$CURRENT -> $$TARGET
	  hash:    $$SRI
	Review with: git diff $$OVERLAY
	Apply with:  make switch
	EOF

# Tail systemd journal
logs:
	journalctl -f

# List system generations
generations:
	sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous system generation
rollback:
	sudo nixos-rebuild switch --rollback
