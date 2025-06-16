{ pkgs, lib, config, ... }:
let
  serviceDomain = "servant.swarsel.win";
  servicePort = 8088;
  serviceName = "jenkins";
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {

    services.jenkins = {
      enable = true;
      withCLI = true;
      port = 8088;
      packages = [ pkgs.stdenv pkgs.git pkgs.jdk17 config.programs.ssh.package pkgs.nix ];
      listenAddress = "0.0.0.0";
      home = "/Vault/apps/jenkins";
    };

    services.nginx = {
      upstreams = {
        "${serviceName}" = {
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
