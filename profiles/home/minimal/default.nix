{ lib, config, ... }:
{
  options.swarselsystems.profiles.minimal = lib.mkEnableOption "is this a personal host";
  config = lib.mkIf config.swarselsystems.profiles.minimal {
    swarselsystems.modules = {
      general = lib.mkDefault true;
      sops = lib.mkDefault true;
      kitty = lib.mkDefault true;
      zsh = lib.mkDefault true;
      git = lib.mkDefault true;
    };
  };

}
