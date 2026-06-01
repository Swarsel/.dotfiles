{ lib, minimal, ... }: # adapt as needed
{

  imports = [
    #   inputs.nixos-hardware.nixosModules.<your-hardware>

    ./hardware-configuration.nix
    ./disk-config.nix

    # ---- SERVER-ONLY ----
    # "${self}/modules/nixos/optional/systemd-networkd-server.nix"      # cloud / single-NIC
    # "${self}/modules/nixos/optional/systemd-networkd-server-home.nix" # home server with VLANs
    # "${self}/modules/nixos/optional/nix-topology-self.nix"

  ] ++ lib.optionals (!minimal) [
    # "${self}/profiles/nixos/personal"
    # "${self}/profiles/nixos/localserver"
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
    rootDisk = "TEMPLATE"; # /dev/disk/by-id/[...]
    isNixos = true;
    isLinux = true;
    isBtrfs = true;
    isImpermanence = true;
    isSecureBoot = true;
    isCrypted = true;
    isSwap = true;
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

} // lib.optionalAttrs (!minimal) {

  # ---- PICK ----:
  #   client:               [ "wlan*" "enp*" ]
  #   common server:        [ "lan" ]
  #   hetzner:              [ "wan" ]
  # networking.nftables.firewall.zones.untrusted.interfaces = [ ];

}
