{ self, config, inputs, lib, minimal, ... }:
let
  primaryUser = config.swarselsystems.mainUser;
  sharedOptions = { };
in
{

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel

    ./disk-config.nix
    ./hardware-configuration.nix

  ];

  swarselprofiles = {
    reduced = lib.mkIf (!minimal) true;
    btrfs = true;
  };

  swarselsystems = lib.recursiveUpdate
    {
      isLaptop = true;
      isNixos = true;
      isBtrfs = true;
      isLinux = true;
      lowResolution = "1280x800";
      highResolution = "1920x1080";
      sharescreen = "eDP-1";
      info = "Lenovo Ideapad 720S-13IKB";
      firewall = lib.mkForce true;
      wallpaper = self + /files/wallpaper/lenovowp.png;
      hasBluetooth = true;
      hasFingerprint = true;
      isImpermanence = true;
      isSecureBoot = false;
      isCrypted = true;
      isSwap = true;
      rootDisk = "/dev/nvme0n1";
      swapSize = "4G";
      hostName = config.node.name;
    }
    sharedOptions;

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
}
