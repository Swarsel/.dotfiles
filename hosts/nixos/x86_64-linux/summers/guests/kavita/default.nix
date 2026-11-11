{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.kavita
    self.modules.nixos.audiobookshelf
  ];

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 3;
    vcpu = 2;

  };

}
