{ self, config, lib, minimal, globals, confLib, ... }:
let
  inherit (confLib.static) nginxAccessRules;
in
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos"
    "${self}/modules/nixos/optional/microvm-guest-shares.nix"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = config.node.name;
    server = {
      wireguard.interfaces = {
        wgHome = {
          isClient = true;
          serverName = "hintbooth";
        };
      };
    };
  };

  globals.general.homeWebProxy = config.node.name;

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 3072 * 1;
    vcpu = 1;
  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    nginx = true;
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
