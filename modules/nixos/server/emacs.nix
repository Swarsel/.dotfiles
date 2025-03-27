{ lib, config, ... }:
{
  options.swarselsystems.server.emacs = lib.mkEnableOption "enable emacs server on server";
  config = lib.mkIf config.swarselsystems.server.emacs {

    networking.firewall.allowedTCPPorts = [ 9812 ];

    services.emacs = {
      enable = true;
      install = true;
      startWithGraphical = false;
    };

  };

}
