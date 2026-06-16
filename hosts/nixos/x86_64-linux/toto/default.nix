{ self, inputs, config, lib, minimal, ... }:
{

  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ] ++ lib.optionals (!minimal) [
    inputs.self.modules.nixos.profile-minimal
  ];

  topology.self.interfaces."bootstrapper" = { };

  node.lockFromBootstrapping = lib.mkForce false;

  networking = {
    hostName = "toto";
    firewall.enable = false;
  };

  sops.secrets.toto-deploy-test.sopsFile = config.node.secretsDir + "/secret.yaml";

  swarselsystems = {
    info = "~SwarselSystems~ remote install helper";
    wallpaper = self + /files/wallpaper/landscape/lenovowp.png;
    isImpermanence = true;
    isCrypted = false;
    isSecureBoot = false;
    isSwap = true;
    swapSize = "2G";
    rootDisk = "/dev/vda";
    isBtrfs = true;
    isLinux = true;
    isLaptop = false;
  };

}
