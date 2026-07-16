{
  self,
  inputs,
  config,
  lib,
  minimal,
  ...
}:
let
  primaryUser = config.swarselsystems.mainUser;
in
{

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel

    ./disk-config.nix
    ./hardware-configuration.nix

  ]
  ++ lib.optionals (!minimal) (
    builtins.attrValues (
      lib.getAttrs [
        "profile-personal"
        "gaming"
        "nswitch-rcm"
        "virtualbox"
        "niri"
        "noctalia"
      ] inputs.self.modules.nixos
    )
  );
  swarselsystems = {
    firewall = lib.mkForce true;
    hasBluetooth = true;
    hasFingerprint = true;
    highResolution = "1920x1080";
    info = "Lenovo Ideapad 720S-13IKB";
    isBtrfs = true;
    isCrypted = true;
    isFullBuild = false;
    isImpermanence = true;
    isLaptop = true;
    isLinux = true;
    isSecureBoot = false;
    isSwap = true;
    lowResolution = "1280x800";
    rootDisk = "/dev/nvme0n1";
    sharescreen = "eDP-1";
    swapSize = "4G";
    wallpaper = self + /files/wallpaper/landscape/lenovowp.png;
  };
  topology.self.interfaces = {
    eth1.network = lib.mkForce "home";
    wifi = { };
  };
  home-manager.users."${primaryUser}" = {
    # home.stateVersion = lib.mkForce "23.05";
    swarselsystems = {
      monitors = {
        main = {
          mode = "1920x1080"; # TEMPLATE
          name = "LG Display 0x04EF Unknown";
          output = "eDP-1";
          position = "1920,0";
          scale = "1";
          workspace = "15:L";
        };
      };
    };
  };
}
// lib.optionalAttrs (!minimal) { }
