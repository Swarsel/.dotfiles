{ self, inputs, config, pkgs, lib, minimal, ... }:
let
  mainUser = "demo";
in
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    {
      _module.args.diskDevice = config.swarselsystems.rootDisk;
    }
  ] ++ lib.optionals (!minimal) [
    inputs.self.modules.nixos.profile-public
  ];

  environment.variables = {
    WLR_RENDERER_ALLOW_SOFTWARE = 1;
  };

  topology.self.interfaces."demo host" = { };

  services.qemuGuest.enable = true;

  boot = {
    loader.systemd-boot.enable = lib.mkForce true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "hotel";
    firewall.enable = true;
  };

  swarselsystems = {
    info = "~SwarselSystems~ demo host";
    wallpaper = self + /files/wallpaper/landscape/lenovowp.png;
    isImpermanence = true;
    isCrypted = true;
    isSecureBoot = false;
    isSwap = true;
    swapSize = "4G";
    rootDisk = "/dev/vda";
    isBtrfs = false;
    inherit mainUser;
    isLinux = true;
    isPublic = true;
  };

}
