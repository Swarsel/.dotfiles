{
  flake.modules.nixos.dns-hostrecord =
    {
      lib,
      config,
      globals,
      dns,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "dns-hostrecord";
          proxy = config.node.name;
        })
        proxyAddress4
        proxyAddress6
        ;
    in
    {
      config = lib.mkIf config.swarselsystems.isCloud {
        swarselsystems.enabledServerModules = [ "dns-hostrecord" ];

        globals.dns.${globals.domains.main}.subdomainRecords = {
          "server.${config.node.name}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };

      };
    }

  ;
}
