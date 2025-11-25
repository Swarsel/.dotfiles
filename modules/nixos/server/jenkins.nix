{ pkgs, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "jenkins"; port = 8088; }) servicePort serviceName serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    services.jenkins = {
      enable = true;
      withCLI = true;
      port = servicePort;
      packages = [ pkgs.stdenv pkgs.git pkgs.jdk17 config.programs.ssh.package pkgs.nix ];
      listenAddress = "0.0.0.0";
      home = "/Vault/apps/${serviceName}";
    };

    nodes.${serviceProxy}.services.nginx = {
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
