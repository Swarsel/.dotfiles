{
  flake.modules.nixos.mpd =
    {
      self,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "mpd";
          port = 6600;
        })
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static) routerServer;
    in
    {
      imports = [
        self.modules.nixos.server-pipewire
      ];
      config = {
        swarselsystems.enabledServerModules = [ "mpd" ];
        globals.monitoring.tcp = confLib.mkTcpMonitoring {
          inherit serviceName servicePort;
          expectedRegex = "^OK MPD";
        };
        sops.secrets.mpd-pw = {
          group = serviceGroup;
          mode = "0440";
          owner = serviceUser;
        };
        users = {
          users = {
            ${serviceUser} = {
              extraGroups = [
                "audio"
                "utmp"
                "users"
                "pipewire"
              ];
              group = serviceGroup;
              isSystemUser = true;
            };
          };
          groups.${serviceGroup} = { };
        };
        services.${serviceName} = {
          enable = true;
          credentials = [
            {
              passwordFile = config.sops.secrets.mpd-pw.path;
              permissions = [
                "read"
                "add"
                "control"
                "admin"
              ];
            }
          ];
          group = serviceGroup;
          openFirewall = true;
          settings = {
            audio_output = [
              {
                name = "PipeWire";
                type = "pipewire";
              }
            ];
            bind_to_address = "any";
            music_directory = "/storage/Music";
            port = servicePort;
          };
          user = serviceUser;
        };
        environment = {
          persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
            directories = [
              {
                directory = "/var/lib/${serviceName}";
                group = serviceGroup;
                user = serviceUser;
              }
            ];
          };
          systemPackages = with pkgs; [
            pciutils
            alsa-utils
            mpv
          ];
        };
        nodes.${routerServer}.networking.nftables.firewall.rules."fritzbox-to-${serviceName}" = {
          extraLines = [
            "ip saddr ${globals.networks.home-lan.cidrv4} tcp dport ${toString servicePort} accept"
          ];
          from = [ "untrusted" ];
          to = [ "vlan-services" ];
        };
      };
    };
}
