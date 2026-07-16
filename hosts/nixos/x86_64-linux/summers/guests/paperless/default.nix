{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.paperless
  ];

  swarselsystems = {
    isImpermanence = true;
    isMicroVM = true;
    proxyHost = "twothreetunnel";
  };

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 8;
    vcpu = 4;
  };

}
