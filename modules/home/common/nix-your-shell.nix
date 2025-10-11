{ lib, config, ... }:
let
  moduleName = "nix-your-shell";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.${moduleName} = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
