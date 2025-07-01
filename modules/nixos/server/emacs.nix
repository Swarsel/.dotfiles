{ lib, config, ... }:
let
  serviceName = "emacs";
  servicePort = 9812;
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} server on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {

    networking.firewall.allowedTCPPorts = [ servicePort ];

    services.${serviceName} = {
      enable = true;
      install = true;
      startWithGraphical = false;
    };

  };

}
