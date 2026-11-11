{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    self.modules.nixos.profile-microvm
    self.modules.nixos.invidious-companion
    self.modules.nixos.socks-proxy
  ];

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 2 - 1;
    vcpu = 2;
  };

}
