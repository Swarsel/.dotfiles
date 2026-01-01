{ lib, config, pkgs, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "minecraft"; port = 25565; dir = "/opt/minecraft"; proxy = config.node.name; }) serviceName servicePort serviceDir serviceDomain proxyAddress4 proxyAddress6 isHome dnsServer;
  inherit (config.swarselsystems) mainUser;
  worldName = "${mainUser}craft";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6 isHome;
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; mode = "0755"; }
    ];

    systemd.services.minecraft-swarselcraft = {
      description = "Minecraft Server";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        User = "root";
        WorkingDirectory = "${serviceDir}/${worldName}";

        ExecStart = "${lib.getExe pkgs.temurin-jre-bin-17} @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.2.20/unix_args.txt nogui";

        Restart = "always";
        RestartSec = 30;
        StandardInput = "null";
      };

      wantedBy = [ "multi-user.target" ];
    };


  };

}
