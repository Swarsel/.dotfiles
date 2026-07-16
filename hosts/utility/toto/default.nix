{
  self,
  inputs,
  config,
  lib,
  minimal,
  ...
}:
{

  imports = [
    ./disk-config.nix
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
    wallpaper = self + /files/wallpaper/landscape/lenovowp.png;
  };

  topology.self.interfaces."bootstrapper" = { };
  sops.secrets.toto-deploy-test.sopsFile = config.node.secretsDir + "/secret.yaml";

  networking = {
    firewall.enable = false;
    hostName = "toto";
  };

  node.lockFromBootstrapping = lib.mkForce false;

}
