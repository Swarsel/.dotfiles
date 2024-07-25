{ config, pkgs, ... }:

{


  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # kernelPackages = pkgs.linuxPackages_latest;
  };


  services.thinkfan = {
    enable = false;
  };
  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;

  services.nswitch-rcm = {
    enable = true;
    package = pkgs.fetchurl {
      url = "https://github.com/Atmosphere-NX/Atmosphere/releases/download/1.3.2/fusee.bin";
      hash = "sha256-5AXzNsny45SPLIrvWJA9/JlOCal5l6Y++Cm+RtlJppI=";
    };
  };




}
