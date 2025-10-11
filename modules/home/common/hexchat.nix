{ lib, config, nixosConfig ? config, ... }:
let
  moduleName = "hexchat";
  inherit (nixosConfig.repo.secrets.common.irc) irc_nick1;
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.${moduleName} = {
      enable = true;
      settings = {
        inherit irc_nick1;
      };
    };
  };

}
