{ inputs, outputs, config, ... }:
{

  imports = builtins.attrValues outputs.homeManagerModules;

  nixpkgs = {
    overlays = outputs.overlaysList;
    config = {
      allowUnfree = true;
    };
  };

  services.xcape = {
    enable = true;
    mapExpression = {
      Control_L = "Escape";
    };
  };

  programs.zsh.initExtra = "
  export GPG_TTY=\"$(tty)\"
  export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  gpgconf --launch gpg-agent
        ";

  swarselsystems = {
    isLaptop = true;
    isNixos = false;
    wallpaper = ../../wallpaper/surfacewp.png;
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
    };
    inputs = {
      "1:1:AT_Translated_Set_2_keyboard" = {
        xkb_layout = "us";
        xkb_options = "grp:win_space_toggle";
        xkb_variant = "altgr-intl";
      };
    };
    keybindings = { };
  };

}
