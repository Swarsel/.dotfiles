{ lib, config, ... }:
{

  options.swarselsystems.modules.optional.vmware = lib.mkEnableOption "optional vmware settings";
  config = lib.mkIf config.swarselsystems.modules.optional.vmware {
    virtualisation.vmware.host.enable = true;
    virtualisation.vmware.guest.enable = true;
  };
}
