{ self, config, inputs, lib, minimal, ... }:
let
  primaryUser = config.swarselsystems.mainUser;
in
{

  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    ./disk-config.nix
    ./hardware-configuration.nix

  ];


  swarselprofiles = {
    personal = lib.mkIf (!minimal) true;
    work = lib.mkIf (!minimal) true;
    uni = lib.mkIf (!minimal) true;
    framework = lib.mkIf (!minimal) true;
    amdcpu = true;
    amdgpu = true;
    hibernation = true;
    btrfs = true;
  };
  swarselsystems = {
    lowResolution = "1280x800";
    highResolution = "2560x1600";
    isLaptop = true;
    isNixos = true;
    isBtrfs = true;
    isLinux = true;
    sharescreen = "eDP-2";
    info = "Framework Laptop 16, 7940HS, RX7700S, 64GB RAM";
    firewall = lib.mkForce true;
    wallpaper = self + /files/wallpaper/lenovowp.png;
    hasBluetooth = true;
    hasFingerprint = true;
    isImpermanence = false;
    isSecureBoot = true;
    isCrypted = true;
    inherit (config.repo.secrets.local) hostName;
    inherit (config.repo.secrets.local) fqdn;
    hibernation.offset = 533760;
  };

  home-manager.users."${primaryUser}" = {
    swarselsystems = {
      isSecondaryGpu = true;
      SecondaryGpuCard = "pci-0000_03_00_0";
      cpuCount = 16;
      temperatureHwmon = {
        isAbsolutePath = true;
        path = "/sys/devices/virtual/thermal/thermal_zone0/";
        input-filename = "temp4_input";
      };
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
    };
  };
}
