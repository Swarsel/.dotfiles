{ lib, config, ... }:
{
  options.swarselsystems.modules.direnv = lib.mkEnableOption "direnv settings";
  config = lib.mkIf config.swarselsystems.modules.direnv {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
  };
}
