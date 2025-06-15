{ lib, config, ... }:
let
  serviceDomain = "synki.swarsel.win";
in
{
  options.swarselsystems.modules.server.ankisync = lib.mkEnableOption "enable ankisync on server";
  config = lib.mkIf config.swarselsystems.modules.server.ankisync {

    networking.firewall.allowedTCPPorts = [ 22701 ];

    sops.secrets.swarsel = { owner = "root"; };

    topology.self.services.anki = {
      name = lib.mkForce "Anki Sync Server";
      info = "https://${serviceDomain}";
    };

    services.anki-sync-server = {
      enable = true;
      port = 27701;
      address = "0.0.0.0";
      openFirewall = true;
      users = [
        {
          username = "Swarsel";
          passwordFile = config.sops.secrets.swarsel.path;
        }
      ];
    };

    services.nginx = {
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:27701";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };

}
