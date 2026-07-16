{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.nfs
    self.modules.nixos.server-syncthing
  ];

  swarselsystems = {
    isImpermanence = true;
    isMicroVM = true;
    nodeRoles = [ "homeSyncthingServer" ];
    proxyHost = "twothreetunnel";
  };

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 4;
    vcpu = 2;
  };

}
