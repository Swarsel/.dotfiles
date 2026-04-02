{ lib, config, ... }:
let
  moduleName = "firezone-client";
  inherit (config.swarselsystems) mainUser;
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "${moduleName} settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    services.firezone.gui-client = {
      enable = true;
      inherit (config.node) name;
      allowedUsers = [ mainUser ];
    };
  };
}
