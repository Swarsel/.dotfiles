{ lib, config, confLib, ... }:
let
  inherit (confLib.gen { name = "emacs"; port = 9812; }) servicePort serviceName;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} server on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    networking.firewall.allowedTCPPorts = [ servicePort ];

    services.${serviceName} = {
      enable = true;
      install = true;
      startWithGraphical = false;
    };

  };

}
