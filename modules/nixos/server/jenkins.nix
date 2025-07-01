{ pkgs, lib, config, ... }:
let
  servicePort = 8088;
  serviceName = "jenkins";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {

    services.jenkins = {
      enable = true;
      withCLI = true;
      port = servicePort;
      packages = [ pkgs.stdenv pkgs.git pkgs.jdk17 config.programs.ssh.package pkgs.nix ];
      listenAddress = "0.0.0.0";
      home = "/Vault/apps/${serviceName}";
    };

    services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "192.168.1.2:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };

}
