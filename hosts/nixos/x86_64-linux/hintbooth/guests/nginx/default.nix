{ self, config, lib, minimal, globals, confLib, ... }:
let
  inherit (confLib.static) nginxAccessRules;
in
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos/optional/microvm-guest-shares.nix"
    "${self}/modules/nixos/server/nginx.nix"
    "${self}/modules/nixos/server/acme.nix"
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
