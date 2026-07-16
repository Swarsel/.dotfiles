{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [

    self.modules.nixos.profile-microvm
    self.modules.nixos.transmission
  ];

  swarselsystems = {
    isImpermanence = true;
    isMicroVM = true;
  };

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 6;
    vcpu = 6;
  };

}
