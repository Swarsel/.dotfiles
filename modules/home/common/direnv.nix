{ lib, config, ... }:
{
  options.swarselmodules.direnv = lib.mkEnableOption "direnv settings";
  config = lib.mkIf config.swarselmodules.direnv {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
  };
}
