{ self, config, lib, globals, inputs, outputs, minimal, nixosConfig ? null, ... }:
let
  domainDefault = service: config.repo.secrets.common.services.domains.${service};
  proxyDefault = config.swarselsystems.proxyHost;

  addressDefault =
    if
      config.swarselsystems.proxyHost != config.node.name
    then
      if
        config.swarselsystems.server.wireguard.interfaces.wgProxy.isClient
      then
        globals.networks."${config.swarselsystems.server.wireguard.interfaces.wgProxy.serverNetConfigPrefix}-wgProxy".hosts.${config.node.name}.ipv4
      else
        globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.ipv4
    else
      "localhost";
in
{
  _module.args = {
    confLib = rec {
      getConfig = if nixosConfig == null then config else nixosConfig;

      gen = { name ? "n/a", user ? name, group ? name, dir ? null, port ? null, domain ? (domainDefault name), address ? addressDefault, proxy ? proxyDefault }: rec {
        servicePort = port;
        serviceName = name;
        specificServiceName = "${name}-${config.node.name}";
        serviceUser = user;
        serviceGroup = group;
        serviceDomain = domain;
        baseDomain = lib.swarselsystems.getBaseDomain domain;
        subDomain = lib.swarselsystems.getSubDomain domain;
        serviceDir = dir;
        serviceAddress = address;
        serviceProxy = proxy;
        proxyAddress4 = globals.hosts.${proxy}.wanAddress4 or null;
        proxyAddress6 = globals.hosts.${proxy}.wanAddress6 or null;
      };

      static = rec {
        inherit (globals.hosts.${config.node.name}) isHome;
        inherit (globals.general) homeProxy webProxy dnsServer homeDnsServer homeWebProxy idmServer oauthServer;
        webProxyIf = "${webProxy}-wgProxy";
        homeProxyIf = "home-wgHome";
        isProxied = config.node.name != webProxy;
        nginxAccessRules = ''
          allow ${globals.networks.home-lan.vlans.home.cidrv4};
          allow ${globals.networks.home-lan.vlans.home.cidrv6};
          allow ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv4};
          allow ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv6};
          deny all;
        '';
        homeServiceAddress = lib.optionalString (config.swarselsystems.server.wireguard.interfaces ? wgHome) globals.networks."${config.swarselsystems.server.wireguard.interfaces.wgHome.serverNetConfigPrefix}-wgHome".hosts.${config.node.name}.ipv4;
      };

      mkMicrovm =
        if config.swarselsystems.withMicroVMs then
          (guestName: {
            ${guestName} = {
              backend = "microvm";
              autostart = true;
              modules = [
                (config.node.configDir + /guests/${guestName}/default.nix)
                {
                  node.secretsDir = config.node.configDir + /secrets/${guestName};
                  node.configDir = config.node.configDir + /guests/${guestName};
                  networking.nftables.firewall = {
                    zones.untrusted.interfaces = lib.mkIf
                      (
                        lib.length config.guests.${guestName}.networking.links == 1
                      )
                      config.guests.${guestName}.networking.links;
                  };
                }
                "${self}/modules/nixos/optional/microvm-guest.nix"
                "${self}/modules/nixos/optional/systemd-networkd-base.nix"
              ];
              microvm = {
                system = config.node.arch;
                baseMac = config.repo.secrets.local.networking.networks.lan.mac;
                interfaces.vlan-services = { };
              };
              extraSpecialArgs = {
                inherit (inputs.self) nodes;
                inherit (inputs.self.pkgs.${config.node.arch}) lib;
                inherit inputs outputs minimal;
                inherit (inputs) self;
                withHomeManager = false;
                microVMParent = config.node.name;
                globals = inputs.self.globals.${config.node.arch};
              };
            };
          }) else (_: { _ = { }; });

      genNginx =
        { serviceAddress
        , serviceName
        , serviceDomain
        , servicePort
        , protocol ? "http"
        , maxBody ? (-1)
        , maxBodyUnit ? ""
        , noSslVerify ? false
        , proxyWebsockets ? false
        , oauth2 ? false
        , oauth2Groups ? [ ]
        , extraConfig ? ""
        , extraConfigLoc ? ""
        }: {
          upstreams = {
            ${serviceName} = {
              servers = {
                "${serviceAddress}:${builtins.toString servicePort}" = { };
              };
            };
          };
          virtualHosts = {
            "${serviceDomain}" = {
              useACMEHost = globals.domains.main;
              forceSSL = true;
              acmeRoot = null;
              oauth2 = {
                enable = lib.mkIf oauth2 true;
                allowedGroups = lib.mkIf (oauth2Groups != [ ]) oauth2Groups;
              };
              locations = {
                "/" = {
                  proxyPass = "${protocol}://${serviceName}";
                  proxyWebsockets = lib.mkIf proxyWebsockets true;
                  extraConfig = lib.optionalString (maxBody != (-1)) ''
                    client_max_body_size ${builtins.toString maxBody}${maxBodyUnit};
                  '' + extraConfigLoc;
                };
              };
              extraConfig = lib.optionalString noSslVerify ''
                proxy_ssl_verify off;
              '' + extraConfig;
            };
          };
        };

    };
  };
}
