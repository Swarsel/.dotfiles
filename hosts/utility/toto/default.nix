{
  root,
  inputs,
  lib,
  pkgs,
  minimal,
  ...
}:
{

  imports = [
    inputs.self.modules.nixos.disk-single-root
    ./hardware-configuration.nix
  ]
  ++ lib.optionals (!minimal) [
    inputs.self.modules.nixos.profile-minimal
  ];

  swarselsystems = {
    info = "~SwarselSystems~ remote install helper";
    isBtrfs = true;
    isCrypted = false;
    isImpermanence = true;
    isLaptop = false;
    isLinux = true;
    isSecureBoot = false;
    isSwap = true;
    rootDisk = "/dev/vda";
    swapSize = "2G";
    wallpaper = root "files/wallpaper/landscape/lenovowp.png";
  };

  topology.self.interfaces.bootstrapper = { };
  sops.secrets.toto-deploy-test = { };
  environment.systemPackages = [ pkgs.yubikey-manager ];

  networking = {
    firewall.enable = false;
    hostName = "toto";
  };

  node.lockFromBootstrapping = lib.mkForce false;

}
