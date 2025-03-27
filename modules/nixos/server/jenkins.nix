{ pkgs, lib, config, ... }:
{
  options.swarselsystems.server.jenkins = lib.mkEnableOption "enable jenkins on server";
  config = lib.mkIf config.swarselsystems.server.jenkins {

    services.jenkins = {
      enable = true;
      withCLI = true;
      port = 8088;
      packages = [ pkgs.stdenv pkgs.git pkgs.jdk17 config.programs.ssh.package pkgs.nix ];
      listenAddress = "127.0.0.1";
      home = "/Vault/apps/jenkins";
    };



    services.nginx = {
      virtualHosts = {
        "servant.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:8088";
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
