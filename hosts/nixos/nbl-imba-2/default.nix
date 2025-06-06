{ self, inputs, lib, primaryUser, ... }:
let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  sharedOptions = {
    isBtrfs = true;
    isLinux = true;
    sharescreen = "eDP-2";
    profiles = {
      personal = true;
      work = true;
      framework = true;
    };
  };
in
{

  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    ./disk-config.nix
    ./hardware-configuration.nix

  ];



  swarselsystems = lib.recursiveUpdate
    {
      firewall = lib.mkForce true;
      wallpaper = self + /wallpaper/lenovowp.png;
      hasBluetooth = true;
      hasFingerprint = true;
      isImpermanence = false;
      isSecureBoot = true;
      isCrypted = true;
      hostName = lib.swarselsystems.getSecret "${secretsDirectory}/work/worklaptop-hostname";
      fqdn = lib.swarselsystems.getSecret "${secretsDirectory}/work/worklaptop-fqdn";
      hibernation.offset = 533760;
      profiles = {
        amdcpu = true;
        amdgpu = true;
        hibernation = true;
        btrfs = true;
      };
    }
    sharedOptions;

  home-manager.users."${primaryUser}" = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      {
        isLaptop = true;
        isNixos = true;
        isSecondaryGpu = true;
        SecondaryGpuCard = "pci-0000_03_00_0";
        cpuCount = 16;
        temperatureHwmon = {
          isAbsolutePath = true;
          path = "/sys/devices/virtual/thermal/thermal_zone0/";
          input-filename = "temp4_input";
        };
        lowResolution = "1280x800";
        highResolution = "2560x1600";
        monitors = {
          main = {
            name = "BOE 0x0BC9 Unknown";
            mode = "2560x1600"; # TEMPLATE
            scale = "1";
            position = "2560,0";
            workspace = "15:L";
            output = "eDP-2";
          };
        };
      }
      sharedOptions;
  };
}
