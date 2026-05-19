{ config, pkgs, ... }:

{
  # sops-nix — encrypted secrets at rest.
  #
  # Active key lives under the LUKS-encrypted /home, NOT in /var/lib/sops-nix.
  # That ties decryption to the LUKS passphrase you already type at boot, so
  # the active key is "passphrase-protected" via the disk encryption layer
  # rather than via age's own passphrase wrapper (which would require a
  # manual decrypt before every nixos-rebuild — annoying).
  #
  # ONE-TIME SETUP:
  #   mkdir -p ~/Vault/Keys/Sam && chmod 700 ~/Vault/Keys/Sam
  #   age-keygen -o ~/Vault/Keys/Sam/age-private.key
  #   chmod 600 ~/Vault/Keys/Sam/age-private.key
  #   grep "public key:" ~/Vault/Keys/Sam/age-private.key | awk '{print $4}' \
  #     > ~/Vault/Keys/Sam/age-public.key
  #   # Passphrase-encrypted backup (for transport to new machines):
  #   age -p -o ~/Vault/Keys/Sam/age-private.key.age \
  #     ~/Vault/Keys/Sam/age-private.key
  #
  #   # Paste the contents of age-public.key into .sops.yaml, replacing the
  #   # AAAA placeholder. Then create the secrets file:
  #   sops secrets.yaml
  #
  # NEW MACHINE WORKFLOW:
  #   1. Install NixOS minimal, set up LUKS on /home as before.
  #   2. Restore Vault from backup (Duplicati) so age-private.key is in place.
  #   3. Clone this repo, run `make switch` — sops-nix reads the key directly.
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";

    # Active decryption key — sits on LUKS-encrypted /home.
    age.keyFile = "/home/sam/Vault/Keys/Sam/age-private.key";

    # Define secrets here as needed
    secrets = {
      "wifi/home" = { };
      "wifi/office" = { };
    };
  };
}
