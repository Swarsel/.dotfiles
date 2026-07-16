{
  self,
  config,
  lib,
  confLib,
  globals,
  minimal,
  ...
}:
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
    isImpermanence = true;
    isMicroVM = true;
    nodeRoles = [ "homeWebProxy" ];
    proxyHost = config.node.name;
  };

}
// lib.optionalAttrs (!minimal) {

  services.nginx = {
    upstreams.fritzbox = {
      servers.${globals.networks.home-lan.hosts.fritzbox.ipv4} = { };
    };
    virtualHosts.${globals.services.fritzbox.domain} = {
      acmeRoot = null;
      extraConfig = ''
        proxy_ssl_verify off;
      ''
      + nginxAccessRules;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://fritzbox";
        proxyWebsockets = true;
      };
      useACMEHost = globals.domains.main;
    };
  };
  microvm = {
    mem = 3072 * 1;
    vcpu = 1;
  };

}
