{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.immich
  ];

  swarselsystems = {
    isImpermanence = true;
    isMicroVM = true;
    proxyHost = "twothreetunnel";
  };

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 16;
    vcpu = 14;
  };

}
