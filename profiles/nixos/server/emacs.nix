{ lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.emacs {

    networking.firewall.allowedTCPPorts = [ 9812 ];

    services.emacs = {
      enable = true;
      install = true;
      startWithGraphical = false;
    };

  };

}
