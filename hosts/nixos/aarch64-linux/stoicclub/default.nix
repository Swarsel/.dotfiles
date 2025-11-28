{ lib, config, minimal, globals, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  topology.self = {
    icon = "devices.cloud-server";
  };
  swarselmodules.server.nginx = false;

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
    networks."10-${config.swarselsystems.server.localNetwork}" = config.systemd.network.networks."10-${config.swarselsystems.server.localNetwork}";
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
          "10-${config.swarselsystems.server.localNetwork}" = {
            address = [
              "${globals.networks."${if config.swarselsystems.isCloud then config.node.name else "home"}-${config.swarselsystems.server.localNetwork}".hosts.${config.node.name}.cidrv4}"
              "${globals.networks."${if config.swarselsystems.isCloud then config.node.name else "home"}-${config.swarselsystems.server.localNetwork}".hosts.${config.node.name}.cidrv6}"
            ];
            routes = [
              {
                Gateway = netConfig.defaultGateway6;
                GatewayOnLink = true;
              }
              {
                Gateway = netConfig.defaultGateway4;
                GatewayOnLink = true;
              }
            ];
            networkConfig = {
              IPv6PrivacyExtensions = true;
              IPv6AcceptRA = false;
            };
            matchConfig.MACAddress = netConfig.networks.${config.swarselsystems.server.localNetwork}.mac;
            linkConfig.RequiredForOnline = "routable";
          };
        };
    };
  };

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 4 vCPUs, 24GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/scsi-360e1a5236f034316a10a97cc703ce9e3";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    isCloud = true;
    proxyHost = "stoicclub";
    server = {
      inherit (config.repo.secrets.local.networking) localNetwork;
    };
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

}
