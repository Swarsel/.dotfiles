{ self, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "nsd"; port = 53; }) serviceName servicePort proxyAddress4 proxyAddress6;
  inherit (config.swarselsystems) sopsFile;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
    swarselsystems.server.dns = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            subdomainRecords = lib.mkOption {
              type = lib.types.attrsOf dns.lib.types.subzone;
              default = { };
            };
          };
        }
      );
    };
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    sops.secrets = {
      tsig-key = { inherit sopsFile; };
    };

    # services.resolved.enable = false;
    networking = {
      # nameservers = [ "1.1.1.1" "8.8.8.8" ];
      firewall = {
        allowedUDPPorts = [ servicePort ];
        allowedTCPPorts = [ servicePort ];
      };
    };

    topology.self.services.${serviceName} = {
      name = lib.toUpper serviceName;
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    services.nsd = {
      enable = true;
      keys = {
        "${globals.domains.main}.${proxyAddress4}" = {
          algorithm = "hmac-sha256";
          keyFile = config.sops.secrets.tsig-key.path;
        };
        "${globals.domains.main}.${proxyAddress6}" = {
          algorithm = "hmac-sha256";
          keyFile = config.sops.secrets.tsig-key.path;
        };
        "${globals.domains.main}" = {
          algorithm = "hmac-sha256";
          keyFile = config.sops.secrets.tsig-key.path;
        };
      };
      interfaces = [
        "10.1.2.157"
        "2603:c020:801f:a0cc::9d"
      ];
      zones = {
        "${globals.domains.main}" =
          let
            keyName4 = "${globals.domains.main}.${proxyAddress4}";
            keyName6 = "${globals.domains.main}.${proxyAddress6}";
            keyName = "${globals.domains.main}";
            transferList = [
              "213.239.242.238 ${keyName4}"
              "2a01:4f8:0:a101::a:1 ${keyName6}"
              "213.133.100.103 ${keyName4}"
              "2a01:4f8:0:1::5ddc:2 ${keyName6}"
              "193.47.99.3 ${keyName4}"
              "2001:67c:192c::add:a3 ${keyName6}"
            ];

          in
          {
            outgoingInterface = "2603:c020:801f:a0cc::9d";
            notify = transferList ++ [
              "216.218.130.2 ${keyName}"
            ];
            provideXFR = transferList ++ [
              "216.218.133.2 ${keyName}"
              "2001:470:600::2 ${keyName}"
            ];

            # dnssec = true;
            data = dns.lib.toString "${globals.domains.main}" (import ./site1.nix { inherit config globals dns proxyAddress4 proxyAddress6; });
          };
      };
    };

  };
}
