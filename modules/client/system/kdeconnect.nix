{
  flake.modules.homeManager.kdeconnect.config = {
    swarselsystems.enabledHomeModules = [ "kdeconnect" ];
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}
