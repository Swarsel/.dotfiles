{ lib, config, ... }:
{
  networking = {
    useDHCP = lib.mkForce false;
    useNetworkd = true;
    dhcpcd.enable = lib.mkIf (!config.swarselsystems.isMicroVM) false;
    renameInterfacesByMac = lib.mkIf (!config.swarselsystems.isMicroVM) (lib.mapAttrs (_: v: if (v ? mac) then v.mac else "") (
      config.repo.secrets.local.networking.networks or { }
    ));
  };

  systemd.network.enable = true;
}
