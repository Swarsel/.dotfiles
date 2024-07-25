{ inputs, outputs, ... }:
{

  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2
    ./hardware-configuration.nix
    ./nixos.nix
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = outputs.mixedModules ++ [
        ./home.nix
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    overlays = outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  #  ------   -----
  # | DP-4 | |eDP-1|
  #  ------   -----
  home-manager.users.swarsel.swarselsystems = {
    isLaptop = true;
    isNixos = true;
    temperatureHwmon = {
      isAbsolutePath = true;
      path = "/sys/devices/platform/thinkpad_hwmon/hwmon/";
      input-filename = "temp1_input";
    };
    monitors = {
      main = {
        name = "California Institute of Technology 0x1407 Unknown";
        mode = "1920x1080"; # TEMPLATE
        scale = "1";
        position = "2560,0";
        workspace = "2:二";
        output = "eDP-1";
      };
      homedesktop = {
        name = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
        mode = "2560x1440";
        scale = "1";
        position = "0,0";
        workspace = "1:一";
        output = "DP-4";
      };
    };
    inputs = {
      "1:1:AT_Translated_Set_2_keyboard" = {
        xkb_layout = "us";
        xkb_options = "grp:win_space_toggle";
        xkb_variant = "altgr-intl";
      };
    };
  };

}
