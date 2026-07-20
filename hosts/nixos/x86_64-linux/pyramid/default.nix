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
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    ./disk-config.nix
    ./hardware-configuration.nix

  ]
  ++ lib.optionals (!minimal) (
    builtins.attrValues (
      lib.getAttrs [
        "profile-personal"
        "amdcpu"
        "amdgpu"
        "framework"
        "gaming"
        "hibernation"
        "nswitch-rcm"
        "virtualbox"
        "work"
        "niri"
        "noctalia"
      ] inputs.self.modules.nixos
    )
  );
  swarselsystems = {
    inherit (config.repo.secrets.local) hostName;
    inherit (config.repo.secrets.local) fqdn;
    firewall = lib.mkForce true;
    hasBluetooth = true;
    hasFingerprint = true;
    hibernation.offset = 533760;
    highResolution = "2560x1600";
    info = "Framework Laptop 16, 7940HS, RX7700S, 64GB RAM";
    isBtrfs = true;
    isCrypted = true;
    isImpermanence = false;
    isLaptop = true;
    isLinux = true;
    isSecureBoot = true;
    lowResolution = "1280x800";
    sharescreen = "eDP-2";
    wallpaper = self + /files/wallpaper/landscape/lenovowp.png;
  };
  topology.self.interfaces = {
    eth1.network = lib.mkForce "home";
    fritz-wg.network = "fritz-wg";
    wifi = { };
  };
  home-manager.users."${primaryUser}".swarselsystems = {
    SecondaryGpuCard = "pci-0000_03_00_0";
    cpuCount = 16;
    isSecondaryGpu = true;
    monitors.main = {
      mode = "2560x1600";
      # name = "BOE 0x0BC9 Unknown";
      name = "BOE 0x0BC9";
      output = "eDP-2";
      position = "2560,0";
      scale = "1";
      workspace = "15:L";
    };
    temperatureHwmon = {
      input-filename = "temp4_input";
      isAbsolutePath = true;
      path = "/sys/devices/virtual/thermal/thermal_zone0/";
    };
  };
}
// lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [
    "wlan*"
    "enp*"
  ];
  # networking.nftables = {
  #   enable = lib.mkForce false;
  #   firewall.enable = lib.mkForce false;
  # };
}
