{ pkgs, lib, config, globals, ... }:
let
  servicePort = 8088;
  serviceName = "jenkins";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.networks.home.hosts.${config.node.name}.ipv4;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

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
            "${serviceAddress}:${builtins.toString servicePort}" = { };
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
