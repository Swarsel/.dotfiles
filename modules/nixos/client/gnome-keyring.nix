{ lib, config, ... }:
{
  options.swarselmodules.gnome-keyring = lib.mkEnableOption "gnome-keyring config";
  config = lib.mkIf config.swarselmodules.gnome-keyring {
    services.gnome.gnome-keyring = {
      enable = true;
    };

    programs.seahorse.enable = true;
  };
}
