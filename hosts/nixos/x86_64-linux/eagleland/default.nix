{ lib, config, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  topology.self = {
    icon = "devices.cloud-server";
  };

  networking = {
    useDHCP = lib.mkForce false;
    useNetworkd = true;
    dhcpcd.enable = false;
    renameInterfacesByMac = lib.mapAttrs (_: v: v.mac) (
      config.repo.secrets.local.networking.networks or { }
    );
  };
  boot.initrd.systemd.network = {
    enable = true;
    networks = {
      inherit (config.systemd.network.networks) "10-wan";
    };
  };

  systemd = {
    network = {
      enable = true;
      wait-online.enable = false;
      networks =
        let
          netConfig = config.repo.secrets.local.networking;
        in
        {
          "10-wan" = {
            address = [
              "${netConfig.wanAddress4}/32"
              "${netConfig.wanAddress6}/64"
            ];
            gateway = [ "fe80::1" ];
            routes = [
              { Destination = netConfig.defaultGateway4; }
              {
                Gateway = netConfig.defaultGateway4;
                GatewayOnLink = true;
              }
            ];
            matchConfig.MACAddress = netConfig.networks.${config.swarselsystems.server.localNetwork}.mac;
            networkConfig.IPv6PrivacyExtensions = "yes";
            linkConfig.RequiredForOnline = "routable";
          };
        };
    };
  };

  swarselmodules.server.mailserver = true;

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "2vCPU, 4GB Ram";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isCloud = true;
    isSwap = true;
    swapSize = "4G";
    rootDisk = "/dev/sda";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    proxyHost = "eagleland";
    server = {
      inherit (config.repo.secrets.local.networking) localNetwork;
    };
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

}
