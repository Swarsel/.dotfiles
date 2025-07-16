{ lib, config, ... }:
{
  options.swarselmodules.eza = lib.mkEnableOption "eza settings";
  config = lib.mkIf config.swarselmodules.eza {
    programs.eza = {
      enable = true;
      icons = "auto";
      git = true;
      extraOptions = [
        "-l"
        "--group-directories-first"
      ];
    };
  };
}
