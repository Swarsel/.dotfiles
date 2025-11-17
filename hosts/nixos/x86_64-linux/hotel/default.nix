{ self, config, pkgs, lib, minimal, ... }:
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
  ];

  environment.variables = {
    WLR_RENDERER_ALLOW_SOFTWARE = 1;
  };

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

  swarselmodules = {
    server = {
      network = lib.mkForce false;
      diskEncryption = lib.mkForce false;
    };
  };

  swarselsystems = {
    info = "~SwarselSystems~ demo host";
    wallpaper = self + /files/wallpaper/lenovowp.png;
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
    isNixos = true;
  };

} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    hotel = true;
    minimal = true;
  };
}
