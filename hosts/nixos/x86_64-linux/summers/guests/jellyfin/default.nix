{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.jellyfin
    self.modules.nixos.seerr
  ];

  swarselsystems = {
    isImpermanence = true;
    isMicroVM = true;
    proxyHost = "twothreetunnel";
  };

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 3;
    vcpu = 4;
  };

}
