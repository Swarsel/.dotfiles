{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [
    calibre
  ];

  sops.secrets.kavita = { owner = "kavita"; };

  services.kavita = {
    enable = true;
    user = "kavita";
    port = 8080;
    tokenKeyFile = config.sops.secrets.kavita.path;
  };

  services.nginx = {
    "scroll.swarsel.win" = {
      enableACME = true;
      forceSSL = true;
      acmeRoot = null;
      locations = {
        "/" = {
          proxyPass = "http://192.168.1.22:8080";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
      };
    };
  };

}
