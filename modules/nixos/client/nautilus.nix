{ lib, config, ... }:
{
  options.swarselmodules.nautilus = lib.mkEnableOption "nautilus config";
  config = lib.mkIf config.swarselmodules.nautilus {
    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "kitty";
    };
  };
}
