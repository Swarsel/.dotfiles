{
  flake.modules.nixos.minecraft =
    {
      self,
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
          dir = "/opt/minecraft";
          name = "minecraft";
          port = 25565;
          proxy = config.node.name;
        })
        proxyAddress4
        proxyAddress6
        serviceDir
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static) isHome;
      inherit (config.swarselsystems) mainUser;
      worldName = "${mainUser}craft";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "minecraft" ];
        topology.self.services.${serviceName} = {
          icon = "${self}/files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = "Minecraft";
        };
        globals = {
          services.${serviceName} = {
            inherit isHome proxyAddress4 proxyAddress6;
            domain = serviceDomain;
          };
          dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
            "${globals.services.${serviceName}.subDomain}" =
              dns.lib.combinators.host proxyAddress4 proxyAddress6;
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            mode = "0755";
          }
        ];
        networking.firewall.allowedTCPPorts = [ servicePort ];
        systemd.services.minecraft-swarselcraft = {
          after = [ "network-online.target" ];
          description = "Minecraft Server";
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.temurin-jre-bin-17} @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.2.20/unix_args.txt nogui";
            Restart = "always";
            RestartSec = 30;
            StandardInput = "null";
            User = "root";
            WorkingDirectory = "${serviceDir}/${worldName}";
          };
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
        };

      };

    };
}
