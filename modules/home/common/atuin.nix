{ lib, config, globals, ... }:
let
  atuinDomain = globals.services.atuin.domain;
in
{
  options.swarselmodules.atuin = lib.mkEnableOption "atuin settings";
  config = lib.mkIf config.swarselmodules.atuin {
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
