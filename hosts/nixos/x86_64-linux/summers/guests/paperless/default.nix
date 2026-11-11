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

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 5;
    vcpu = 4;
  };

}
