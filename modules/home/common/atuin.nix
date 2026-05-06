{ globals, ... }:
let
  atuinDomain = globals.services.atuin.domain;
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "atuin" ];
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://${atuinDomain}";
      };
    };
  };
}
