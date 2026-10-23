{
  flake.modules.nixos.slskd =
    {
      root,
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/slskd";
          name = "slskd";
          port = 5030;
        })
        serviceDir
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.gen { name = "transmission"; }) serviceDomain;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        ;
      inherit (config.swarselsystems) sopsFile;

      piaNamespace = "pia-slsk";
      piaTunnel = config.services.pia-netns.tunnels.${piaNamespace};
      urlBase = "/${serviceName}";
      downloadDir = "/storage/Music/${serviceName}";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}${urlBase}";
          name = serviceName;
        };
        globals = {
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            path = "${urlBase}/";
          };
          networks = confLib.mkDualFirewallRules {
            forWebProxy = false;
            tcpPorts = [ servicePort ];
          };
        };
        sops = {
          secrets = {
            slskd-soulseek-password = { inherit sopsFile; };
            slskd-soulseek-username = { inherit sopsFile; };
            slskd-web-password = { inherit sopsFile; };
          };
          templates."slskd.env".content = ''
            SLSKD_SLSK_USERNAME=${config.sops.placeholder.slskd-soulseek-username}
            SLSKD_SLSK_PASSWORD=${config.sops.placeholder.slskd-soulseek-password}
            SLSKD_USERNAME=${config.swarselsystems.mainUser}
            SLSKD_PASSWORD=${config.sops.placeholder.slskd-web-password}
          '';
        };
        users = {
          users.${serviceUser}.extraGroups = [ "users" ];
          persistentIds.${serviceName} = confLib.mkIds 937;
        };
        services = {
          ${serviceName} = {
            enable = true;
            environmentFile = config.sops.templates."slskd.env".path;
            settings = {
              directories = {
                downloads = downloadDir;
                incomplete = "${serviceDir}/incomplete";
              };
              shares.directories = [ "/storage/Music" ];
              transfers = {
                download.speed_limit = 6000;
                upload = {
                  slots = 5;
                  speed_limit = 1000;
                };
              };
              web = {
                port = servicePort;
                url_base = urlBase;
              };
            };
          };
          pia-netns.tunnels.${piaNamespace} = {
            credentialsFile = config.sops.secrets.pia.path;
            dns = true;
            portForwarding.enable = true;
            region = "sweden";
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        systemd = {
          services = {
            ${serviceName} = {
              after = [ piaTunnel.unit ];
              bindsTo = [ piaTunnel.unit ];
              partOf = [ piaTunnel.unit ];
              requires = [ piaTunnel.unit ];
              serviceConfig = {
                BindReadOnlyPaths = [ "/etc/netns/${piaNamespace}/resolv.conf:/etc/resolv.conf" ];
                ExecStart =
                  let
                    cfg = config.services.${serviceName};
                    configurationYaml = (pkgs.formats.yaml { }).generate "slskd.yml" (
                      lib.filterAttrsRecursive (_: value: (builtins.tryEval value).success && value != null) (
                        lib.removeAttrs cfg.settings [ "global" ]
                      )
                    );
                  in
                  lib.mkForce (
                    pkgs.writeShellScript "${serviceName}-start" ''
                      exec ${cfg.package}/bin/slskd \
                        --app-dir ${serviceDir} \
                        --config ${configurationYaml} \
                        --slsk-listen-port "$(cat "$CREDENTIALS_DIRECTORY/listen-port")"
                    ''
                  );
                LoadCredential = [ "listen-port:${piaTunnel.portForwarding.portFile}" ];
                NetworkNamespacePath = piaTunnel.netnsPath;
                PrivateUsers = lib.mkForce false;
                UMask = "0002";
              };
              wantedBy = [ piaTunnel.unit ];
            };
            "${serviceName}-web-forward" =
              let
                inner = pkgs.writeShellScript "${serviceName}-web-into-netns" ''
                  exec ${pkgs.iproute2}/bin/ip netns exec ${piaNamespace} \
                    ${pkgs.socat}/bin/socat - TCP:127.0.0.1:${toString servicePort}
                '';
              in
              {
                after = [ "${serviceName}.service" ];
                bindsTo = [ "${serviceName}.service" ];
                description = "Forward 0.0.0.0:${toString servicePort} into the ${piaNamespace} netns";
                partOf = [ "${serviceName}.service" ];
                serviceConfig = {
                  ExecStart = pkgs.writeShellScript "${serviceName}-web-forward" ''
                    exec ${pkgs.socat}/bin/socat \
                      TCP-LISTEN:${toString servicePort},reuseaddr,fork \
                      EXEC:${inner}
                  '';
                  Restart = "on-failure";
                  RestartSec = "5s";
                  Type = "simple";
                };
                wantedBy = [
                  "multi-user.target"
                  "${serviceName}.service"
                ];
              };
          };
          tmpfiles.rules = [
            "d ${downloadDir} 0775 ${serviceUser} users -"
            "d ${serviceDir}/incomplete 0750 ${serviceUser} ${serviceGroup} -"
          ];
        };
        nodes.${homeWebProxy}.services.nginx = lib.mkIf isHome {
          upstreams.${serviceName}.servers = {
            "${homeServiceAddress}:${builtins.toString servicePort}" = { };
          };
          virtualHosts.${serviceDomain}.locations.${urlBase} = {
            extraConfig = ''
              client_max_body_size 0;
            '';
            proxyPass = "http://${serviceName}";
            proxyWebsockets = true;
          };
        };
      };
    }

  ;
}
