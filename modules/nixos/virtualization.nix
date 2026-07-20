{ config, pkgs, ... }:

{
  virtualisation = {
    docker = {
      enable = true;
      # docker_28 was marked insecure (unmaintained since 2025-11); track the next major.
      package = pkgs.docker_29;

      # Cap per-container log files so a chatty container can't silently fill
      # the disk (default json-file driver is unbounded). Keep live-restore
      # so running containers survive daemon restarts on `nixos-rebuild switch`.
      daemon.settings = {
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };
        live-restore = true;
      };
    };

    libvirtd.enable = true;
  };

  # GUI for managing libvirt VMs
  programs.virt-manager.enable = true;

  # ATTENTION: WinBoat (currently your Photoshop solution) uses Docker, not
  # libvirt + FreeRDP. If you ever switch to a WinApps-style setup that
  # passes Windows app windows through to Linux as native windows, add
  # `freerdp` to environment.systemPackages here.

  # Default virsh / virt-manager to system mode (vs the per-user session mode,
  # which can't allocate full host resources to a VM).
  environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";
}
