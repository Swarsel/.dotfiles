{
  flake.modules.nixos.mpd =
    { self, lib, config, pkgs, confLib, ... }:
    let
      inherit (config.swarselsystems) sopsFile;
      inherit (confLib.gen { name = "mpd"; port = 6600; }) servicePort serviceName serviceUser serviceGroup;
      inherit (confLib.static) routerServer;
    in
    {
      imports = [
        self.modules.nixos.server-pipewire
      ];

      config = {
        swarselsystems.enabledServerModules = [ "mpd" ];
        users = {
          groups = {
            mpd = { };
          };

          users = {
            ${serviceUser} = {
              isSystemUser = true;
              group = serviceGroup;
              extraGroups = [ "audio" "utmp" "users" "pipewire" ];
            };
          };
        };

        sops = {
          secrets.mpd-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        };

        environment.systemPackages = with pkgs; [
          pciutils
          alsa-utils
          mpv
        ];

        # topology.self.services.${serviceName} = {
        #   info = "http://localhost:${builtins.toString servicePort}";
        #   icon = lib.mkForce "${self}/files/topology-images/mpd.png";
        # };

        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [{ directory = "/var/lib/${serviceName}"; user = "mpd"; group = "mpd"; }];
        };

        services.${serviceName} = {
          enable = true;
          openFirewall = true;
          settings = {
            music_directory = "/storage/Music";
            bind_to_address = "any";
            port = servicePort;
            audio_output = [
              {
                type = "pipewire";
                name = "PipeWire";
              }
            ];
          };
          user = serviceUser;
          group = serviceGroup;
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
        };

        nodes.${routerServer}.networking.nftables.firewall.rules."fritzbox-to-${serviceName}" = {
          from = [ "untrusted" ];
          to = [ "vlan-services" ];
          extraLines = [
            "ip saddr 192.168.178.0/24 tcp dport ${toString servicePort} accept"
          ];
        };
      };

    }

  ;
}
