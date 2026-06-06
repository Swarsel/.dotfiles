{ self, lib, minimal, ... }:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.nfs
    self.modules.nixos.server-syncthing
  ];

  swarselsystems = {
    nodeRoles = [ "homeSyncthingServer" ];
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 4;
    vcpu = 2;
  };

}
