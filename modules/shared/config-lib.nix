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

      gen = { name ? "n/a", user ? name, group ? user, dir ? null, port ? null, domain ? (domainDefault name), address ? addressDefault, proxy ? proxyDefault }: rec {
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

      mkIds = id: {
        uid = id;
        gid = id;
      };

      mkDeviceMac = id:
        let
          mod = n: d: n - (n / d) * d;
          toHexByte = n:
            let
              hex = "0123456789abcdef";
              hi = n / 16;
              lo = mod n 16;
            in
            builtins.substring hi 1 hex
            + builtins.substring lo 1 hex;

          max = 16777215; # 256^3 - 1

          b1 = id / (256 * 256);
          r1 = mod id (256 * 256);
          b2 = r1 / 256;
          b3 = mod r1 256;
        in
        if
          (id <= max)
        then
          (builtins.concatStringsSep ":"
            (map toHexByte [ b1 b2 b3 ]))
        else
          (throw "Device MAC ID too large (max is 16777215)");

      mkMicrovm =
        if config.swarselsystems.withMicroVMs then
          (guestName:
            { eternorPaths ? [ ]
            , withZfs ? false
            , ...
            }:
            {
              ${guestName} =
                {
                  backend = "microvm";
                  autostart = true;
                  zfs = lib.mkIf withZfs
                    ({
                      # stateful config usually bind-mounted to /var/lib/ that should be backed up remotely
                      "/state" = {
                        pool = "Vault";
                        dataset = "guests/${guestName}/state";
                      };
                      # other stuff that should only reside on zfs, not backed up remotely
                      "/persist" = {
                        pool = "Vault";
                        dataset = "guests/${guestName}/persist";
                      };
                    } // lib.optionalAttrs (eternorPaths != [ ])
                      (lib.listToAttrs (map
                        # data that is pulled in externally by services, some of which is backed up externally
                        (eternorPath:
                          lib.nameValuePair "/storage/${eternorPath}" {
                            pool = "Vault";
                            dataset = "Eternor/${eternorPath}";
                          })
                        eternorPaths)));
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

                      fileSystems = {
                        "/persist".neededForBoot = true;
                      } // lib.optionalAttrs withZfs {
                        "/state".neededForBoot = true;
                      };
                    }
                    "${self}/modules/nixos/optional/microvm-guest.nix"
                    "${self}/modules/nixos/optional/systemd-networkd-base.nix"
                  ];
                  microvm = {
                    system = config.node.arch;
                    baseMac = config.repo.secrets.local.networking.networks.lan.mac;
                    interfaces.vlan-services = {
                      mac = lib.mkForce "02:${lib.substring 3 5 config.guests.${guestName}.microvm.baseMac}:${mkDeviceMac globals.networks.home-lan.vlans.services.hosts."${config.node.name}-${guestName}".id}";

                    };
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
            }) else
          (_: {
            _ = { };
          });

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
