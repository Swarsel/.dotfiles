{ lib, minimal, ... }: # adapt as needed
{

  imports = [
    #   inputs.nixos-hardware.nixosModules.<your-hardware>

    ./hardware-configuration.nix
    ./disk-config.nix

    # ---- SERVER-ONLY ----
    # self.modules.nixos.systemd-networkd-server      # cloud / single-NIC
    # self.modules.nixos.systemd-networkd-server-home # home server with VLANs
    # self.modules.nixos.nix-topology-self

  ]
  ++ lib.optionals (!minimal) [
    # self.modules.nixos.profile-personal
    # self.modules.nixos.profile-localserver
  ];

  # ---- CLIENT-ONLY ----
  # topology.self.interfaces = {
  #   eth1.network = lib.mkForce "home";
  #   wifi = { };
  # };

  # ---- SERVER-ONLY ----
  # topology.self = {
  #   icon = "devices.cloud-server";
  #   interfaces.lan = { };
  # };

  swarselsystems = {
    info = "TEMPLATE";
    isBtrfs = true;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = true;
    isSwap = true;
    rootDisk = "TEMPLATE"; # /dev/disk/by-id/[...]
    swapSize = "16G";
    # ---- CLIENT-ONLY ----
    # isLaptop = true;
    # hasBluetooth = true;
    # hasFingerprint = true;
    # wallpaper = self + <path>;
    # lowResolution = "<resolution for sharing the screen>";
    # highResolution = "<standard resolution>";
    # sharescreen = "<output>";
    # ---- SERVER-ONLY ----
    # flakePath = "/root/.dotfiles";
    # isCloud = true;
    # proxyHost = "twothreetunnel";
    # nodeRoles = [ ];
  };

}
// lib.optionalAttrs (!minimal) {

  # ---- PICK ----:
  #   client:               [ "wlan*" "enp*" ]
  #   common server:        [ "lan" ]
  #   hetzner:              [ "wan" ]
  # networking.nftables.firewall.zones.untrusted.interfaces = [ ];

}
