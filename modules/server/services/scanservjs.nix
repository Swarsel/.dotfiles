{
  flake.modules.nixos.scanservjs =
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
          name = "scanservjs";
          port = 8090;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeProxyIf
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        ;
      paperless = globals.services.paperless;
      uploadAction = "Send to Paperless";
    in
    {
      imports = [ self.modules.nixos.network-scanner ];
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName}.info = "https://${serviceDomain}";
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
            extra.extraConfig.node = config.node.name;
          };
          monitoring = {
            http = confLib.mkHttpMonitoring { inherit serviceName servicePort; };
            systemd = confLib.mkSystemdMonitoring {
              inherit serviceName;
              unit = "${serviceName}.service";
            };
          };
          networks = lib.mkMerge [
            (confLib.mkDualFirewallRules {
              forWebProxy = false;
              tcpPorts = [ servicePort ];
            })
            {
              ${homeProxyIf}.hosts.${paperless.extraConfig.node}.firewallRuleForNode.${config.node.name}.allowedTCPPorts =
                [
                  paperless.extraConfig.port
                ];
            }
          ];
        };
        sops = {
          secrets.scanservjs-paperless-token = { };
          templates.scanservjs-paperless-header.content = ''
            Authorization: Token ${config.sops.placeholder.scanservjs-paperless-token}
          '';
        };
        users.persistentIds.${serviceName} = confLib.mkIds 930;
        services.${serviceName} = {
          enable = true;
          # pipeline afterActions are not awaited, so a thrown error would crash the server
          extraActions = [
            ''
              {
                name: '${uploadAction}',
                async execute(fileInfo) {
                  const { execFile } = require('node:child_process');
                  const { promisify } = require('node:util');
                  try {
                    await promisify(execFile)('${lib.getExe pkgs.curl}', [
                      '--fail-with-body',
                      '--silent',
                      '--show-error',
                      '--header', 'Host: ${paperless.domain}',
                      '--header', `@''${process.env.CREDENTIALS_DIRECTORY}/paperless-header`,
                      '--form', `document=@''${fileInfo.fullname}`,
                      'http://${paperless.homeServiceAddress}:${toString paperless.extraConfig.port}/api/documents/post_document/'
                    ]);
                    fileInfo.delete();
                  } catch (error) {
                    console.error(`upload of ''${fileInfo.fullname} to paperless failed: ''${error.stderr || error.message}`);
                  }
                }
              }
            ''
          ];
          extraConfig = ''
            config.pipelines.unshift({
              extension: 'pdf',
              description: 'Paperless | PDF (JPG | @:pipeline.high-quality)',
              afterAction: '${uploadAction}',
              commands: [
                'while read filename ; do convert -quality 92 $filename converted-$(date +%s.%N).jpg ; done && ls converted-*.jpg',
                'convert @- scan-0000.pdf',
                'ls scan-*.*'
              ]
            });
          '';
          settings = {
            host = "0.0.0.0";
            port = servicePort;
          };
        };
        systemd.services.${serviceName}.serviceConfig.LoadCredential = [
          "paperless-header:${config.sops.templates.scanservjs-paperless-header.path}"
        ];
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                oauth2 = true;
                oauth2Groups = [ "${serviceName}_access" ];
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];
      };
    };
}
