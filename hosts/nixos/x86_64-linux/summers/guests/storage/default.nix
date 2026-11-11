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

  swarselsystems.nodeRoles = [ "homeSyncthingServer" ];

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 2 - 1;
    vcpu = 2;
  };

}
