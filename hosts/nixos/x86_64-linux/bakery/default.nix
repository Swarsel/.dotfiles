{ self, config, inputs, lib, minimal, ... }:
let
  primaryUser = config.swarselsystems.mainUser;
in
{

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel

    ./disk-config.nix
    ./hardware-configuration.nix

  ] ++ lib.optionals (!minimal) (builtins.attrValues (lib.getAttrs [
    "profile-personal"
    "gaming"
    "nswitch-rcm"
    "virtualbox"
    "niri"
    "noctalia"
  ]
    inputs.self.modules.nixos));

  topology.self.interfaces = {
    eth1.network = lib.mkForce "home";
    wifi = { };
  };

  swarselsystems = {
    isLaptop = true;
    isBtrfs = true;
    isLinux = true;
    isFullBuild = false;
    lowResolution = "1280x800";
    highResolution = "1920x1080";
    sharescreen = "eDP-1";
    info = "Lenovo Ideapad 720S-13IKB";
    firewall = lib.mkForce true;
    wallpaper = self + /files/wallpaper/landscape/lenovowp.png;
    hasBluetooth = true;
    hasFingerprint = true;
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = true;
    rootDisk = "/dev/nvme0n1";
    swapSize = "4G";
  };

  home-manager.users."${primaryUser}" = {
    # home.stateVersion = lib.mkForce "23.05";
    swarselsystems = {
      monitors = {
        main = {
          name = "LG Display 0x04EF Unknown";
          mode = "1920x1080"; # TEMPLATE
          scale = "1";
          position = "1920,0";
          workspace = "15:L";
          output = "eDP-1";
        };
      };
    };
  };
} // lib.optionalAttrs (!minimal) { }
