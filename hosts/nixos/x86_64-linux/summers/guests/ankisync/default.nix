{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.ankisync
  ];

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 1;
    vcpu = 1;
  };

}
