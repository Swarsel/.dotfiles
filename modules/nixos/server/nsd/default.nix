{ inputs, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "nsd"; port = 53; }) serviceName;
  # servicePort = 53;
  # serviceDomain = config.repo.secrets.common.services.domains."${serviceName}";
  # serviceAddress = globals.networks."${if config.swarselsystems.isCloud then config.node.name else "home"}-${config.swarselsystems.server.localNetwork}".hosts.${config.node.name}.ipv4;

in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
    swarselsystems.server.dns = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            subdomainRecords = lib.mkOption {
              type = lib.types.attrsOf inputs.dns.subzone;
              default = { };
            };
          };
        }
      );
    };
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {
    services.nsd = {
      enable = true;
      zones = {
        "${globals.domains.main}" = {
          # provideXFR = [ ... ];
          # notify = [ ... ];
          data = dns.lib.toString "${globals.domains.main}" (import ./site1.nix { inherit config globals dns; });
        };
      };
    };

  };
}
