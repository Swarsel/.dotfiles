{ confLib, ... }:
let
  inherit (confLib.gen { name = "emacs"; port = 9812; }) servicePort serviceName;
in
{
  config = {
    swarselsystems.enabledServerModules = [ "emacs" ];

    networking.firewall.allowedTCPPorts = [ servicePort ];

    services.${serviceName} = {
      enable = true;
      install = true;
      startWithGraphical = false;
    };

  };

}
