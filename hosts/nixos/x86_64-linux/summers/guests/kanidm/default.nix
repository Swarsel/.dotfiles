{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.kanidm
  ];

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 2 - 1;
    vcpu = 2;
  };

}
