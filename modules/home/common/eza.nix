{ lib, config, ... }:
{
  options.swarselsystems.modules.eza = lib.mkEnableOption "eza settings";
  config = lib.mkIf config.swarselsystems.modules.eza {
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
