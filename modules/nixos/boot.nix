{ config, pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;

    # Alternative: GRUB
    # grub = {
    #   enable = true;
    #   device = "/dev/sda"; # or "nodev" for EFI
    #   useOSProber = true;
    # };
  };

  # ATTENTION: Encrypted swap partition (nvme0n1p1).
  # `nixos-generate-config` emits boot.initrd.luks.devices for root/home but
  # NOT for swap LUKS volumes — without this entry the mapper device is never
  # created at boot, so swapDevices in hardware-configuration.nix silently
  # fails AND the partition shows up in Files as an unlocked drive.
  # `boot.initrd.luks.reusePassphrases = true` (default) means if this LUKS
  # passphrase matches root/home the prompt is shared — you only type once.
  boot.initrd.luks.devices."luks-271ccf8c-bc8d-4b69-938c-19dabd8e3da0".device =
    "/dev/disk/by-uuid/271ccf8c-bc8d-4b69-938c-19dabd8e3da0";

  # boot.kernelParams = [ ];
  # boot.kernelModules = [ ];
  # boot.kernel.sysctl = { };

  # NTFS read/write support (uncomment to mount Windows / external NTFS drives).
  # Pairs with the `ntfs3g` userspace driver if you need older-style mounts.
  # boot.supportedFilesystems = [ "ntfs" ];
}
