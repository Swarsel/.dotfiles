{ lib, config, ... }:
{
  options.swarselprofiles.minimal = lib.mkEnableOption "is this a personal host";
  config = lib.mkIf config.swarselprofiles.minimal {
    swarselmodules = {
      general = lib.mkDefault true;
      sops = lib.mkDefault true;
      kitty = lib.mkDefault true;
      zsh = lib.mkDefault true;
      git = lib.mkDefault true;
    };
  };

}
