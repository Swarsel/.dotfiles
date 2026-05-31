{ self, lib, config, globals, confLib, ... }:
let
  inherit (config.swarselsystems) sopsFile;
  inherit (confLib.gen { name = "ankisync"; port = 27701; }) servicePort serviceName serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules;

  ankiUser = globals.user.name;
in
{
  config = {
    swarselsystems.enabledServerModules = [ "ankisync" ];

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    sops.secrets.anki-pw = { inherit sopsFile; owner = "root"; };

    topology.self.services.anki = {
      name = lib.mkForce "Anki Sync Server";
      icon = lib.mkForce "${self}/files/topology-images/${serviceName}.png";
      info = "https://${serviceDomain}";
    };

    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; expectedStatus = 404; };
      dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/private/anki-sync-server"; }];
    };

    services.anki-sync-server = {
      enable = true;
      port = servicePort;
      address = "0.0.0.0";
      # openFirewall = true;
      users = [
        {
          username = ankiUser;
          passwordFile = config.sops.secrets.anki-pw.path;
        }
      ];
    };

    nodes = {
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
