{
  flake.modules.nixos.knot =
    {
      root,
      config,
      lib,
      pkgs,
      confLib,
      dns,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/knot";
          name = "knot";
          port = 53;
          proxy = config.node.name;
        })
        proxyAddress4
        proxyAddress6
        serviceDir
        serviceName
        servicePort
        ;
      inherit (config.swarselsystems) sopsFile;
      listenAddress4 = "10.1.2.157";
      listenAddress6 = "2603:c020:801f:a0cc::9d";
      keyName = globals.domains.main;
      keyName4 = "${keyName}.${proxyAddress4}";
      keyName6 = "${keyName}.${
        lib.concatMapStringsSep "-" (lib.fixedWidthString 4 "0") (
          lib.splitString ":" (lib.network.ipv6.fromString proxyAddress6).address
        )
      }";
      mkRemotes =
        key:
        map (address: {
          inherit address key;
        });
      hetzner =
        mkRemotes keyName4 [
          "213.239.242.238"
          "213.133.100.103"
          "193.47.99.3"
        ]
        ++ mkRemotes keyName6 [
          "2a01:4f8:0:a101::a:1"
          "2a01:4f8:0:1::5ddc:2"
          "2001:67c:192c::add:a3"
        ];
      heNotify = mkRemotes keyName [ "216.218.130.2" ];
      heTransfer = mkRemotes keyName [
        "216.218.133.2"
        "2001:470:600::2"
      ];
      remoteIds = map (remote: remote.address);
      mkZoneFile = name: data: pkgs.writeText "${name}.zone" (dns.lib.toString name data);
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          name = "Knot DNS";
        };
        globals.monitoring.dns = confLib.mkDnsMonitoring {
          inherit serviceName;
          address = "${listenAddress4}:${toString servicePort}";
          queryName = globals.domains.main;
        };
        sops = {
          secrets.tsig-key = { inherit sopsFile; };
          templates."knot-tsig.conf" = {
            content =
              "key:\n"
              +
                lib.concatMapStrings
                  (id: ''
                    - id: ${id}
                      algorithm: hmac-sha256
                      secret: ${config.sops.placeholder.tsig-key}
                  '')
                  [
                    keyName
                    keyName4
                    keyName6
                  ];
            owner = "knot";
          };
        };
        users.persistentIds.knot = confLib.mkIds 931;
        services.knot = {
          enable = true;
          keyFiles = [ config.sops.templates."knot-tsig.conf".path ];
          settings = {
            acl.secondaries = {
              action = "transfer";
              remote = remoteIds (hetzner ++ heTransfer);
            };
            remote = lib.listToAttrs (
              map (
                remote:
                lib.nameValuePair remote.address (
                  remote
                  // {
                    via = [
                      listenAddress4
                      listenAddress6
                    ];
                  }
                )
              ) (hetzner ++ heNotify ++ heTransfer)
            );
            server.listen = [
              "${listenAddress4}@${toString servicePort}"
              "${listenAddress6}@${toString servicePort}"
            ];
            template.default = {
              journal-content = "all";
              serial-policy = "dateserial";
              zonefile-load = "difference-no-serial";
              zonefile-sync = -1;
            };
            zone = {
              "${globals.domains.main}" = {
                acl = [ "secondaries" ];
                dnssec-signing = true;
                file = mkZoneFile globals.domains.main (
                  import ./_dns-site1.nix {
                    inherit (confLib.static) dmarcMailAddress;
                    inherit
                      config
                      dns
                      globals
                      proxyAddress4
                      proxyAddress6
                      ;
                  }
                );
                notify = remoteIds (hetzner ++ heNotify);
              };
              "${globals.domains.reverse6}".file = mkZoneFile globals.domains.reverse6 (
                import ./_dns-reverse6.nix { inherit globals; }
              );
            };
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            group = "knot";
            mode = "0700";
            user = "knot";
          }
        ];
        networking.firewall = {
          allowedTCPPorts = [ servicePort ];
          allowedUDPPorts = [ servicePort ];
        };
      };
    };
}
