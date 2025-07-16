{ lib, config, ... }:
{

  options.swarselmodules.optional.vmware = lib.mkEnableOption "optional vmware settings";
  config = lib.mkIf config.swarselmodules.optional.vmware {
    virtualisation.vmware.host.enable = true;
    virtualisation.vmware.guest.enable = true;
  };
}
