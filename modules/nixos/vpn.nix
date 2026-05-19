{ config, pkgs, ... }:

{
  # Tailscale - mesh VPN
  services.tailscale.enable = true;

  # Cloudflare Warp - privacy/performance VPN
  services.cloudflare-warp.enable = true;

  # WireGuard - modern VPN protocol (kernel module is built-in)
  environment.systemPackages = with pkgs; [
    wireguard-tools # wg, wg-quick CLI tools
  ];

  # TODO: Configure WireGuard interfaces declaratively when needed:
  # networking.wireguard.interfaces.wg0 = {
  #   ips = [ "10.0.0.2/24" ];
  #   privateKeyFile = "/path/to/private.key";
  #   peers = [{
  #     publicKey = "...";
  #     allowedIPs = [ "0.0.0.0/0" ];
  #     endpoint = "vpn.example.com:51820";
  #   }];
  # };
}
