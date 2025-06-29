{ lib, config, ... }:
{
  options.swarselsystems.modules.atuin = lib.mkEnableOption "atuin settings";
  config = lib.mkIf config.swarselsystems.modules.atuin {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://shellhistory.swarsel.win";
      };
    };
  };
}
