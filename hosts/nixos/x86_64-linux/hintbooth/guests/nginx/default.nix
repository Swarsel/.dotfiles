{ self, config, lib, minimal, globals, confLib, ... }:
let
  inherit (confLib.static) nginxAccessRules;
in
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.microvm-guest-shares
    self.modules.nixos.oauth2-proxy
    self.modules.nixos.nginx
    self.modules.nixos.nginx-exporter
    self.modules.nixos.acme
    self.modules.nixos.nginx-otel
  ];

  swarselsystems = {
    nodeRoles = [ "homeWebProxy" ];
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = config.node.name;
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 3072 * 1;
    vcpu = 1;
  };

  services.nginx = {
    upstreams.fritzbox = {
      servers.${globals.networks.home-lan.hosts.fritzbox.ipv4} = { };
    };
    virtualHosts.${globals.services.fritzbox.domain} = {
      useACMEHost = globals.domains.main;
      forceSSL = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://fritzbox";
        proxyWebsockets = true;
      };
      extraConfig = ''
        proxy_ssl_verify off;
      '' + nginxAccessRules;
    };
  };

}
