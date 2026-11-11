{
  flake.modules.nixos.systemd-networkd-base =
    { config, lib, ... }:
    {
      networking = {
        dhcpcd.enable = lib.mkIf (!config.swarselsystems.isMicroVM) false;
        renameInterfacesByMac = lib.mkIf (!config.swarselsystems.isMicroVM) (
          lib.mapAttrs (_: v: v.mac or "") (config.repo.secrets.local.networking.networks or { })
        );
        useDHCP = lib.mkForce false;
        useNetworkd = true;
      };

      systemd.network.enable = true;
    };
}
