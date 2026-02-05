{ self, config, inputs, lib, minimal, ... }:
let
  primaryUser = config.swarselsystems.mainUser;
in
{

  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    ./disk-config.nix
    ./hardware-configuration.nix

    "${self}/modules/nixos/optional/amdcpu.nix"
    "${self}/modules/nixos/optional/amdgpu.nix"
    "${self}/modules/nixos/optional/framework.nix"
    "${self}/modules/nixos/optional/gaming.nix"
    "${self}/modules/nixos/optional/hibernation.nix"
    "${self}/modules/nixos/optional/nswitch-rcm.nix"
    "${self}/modules/nixos/optional/virtualbox.nix"
    "${self}/modules/nixos/optional/work.nix"
    "${self}/modules/nixos/optional/niri.nix"
    "${self}/modules/nixos/optional/noctalia.nix"
  ];

  topology.self = {
    interfaces = {
      eth1.network = lib.mkForce "home";
      wifi = { };
      fritz-wg.network = "fritz-wg";
    };
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
          # name = "BOE 0x0BC9 Unknown";
          name = "BOE 0x0BC9";
          mode = "2560x1600";
          scale = "1";
          position = "2560,0";
          workspace = "15:L";
          output = "eDP-2";
        };
      };
    };
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    personal = true;
  };

  # networking.nftables = {
  #   enable = lib.mkForce false;
  #   firewall.enable = lib.mkForce false;
  # };
}
