{
  self,
  config,
  lib,
  minimal,
  ...
}:
{
  imports = [

    self.modules.nixos.profile-microvm
    self.modules.nixos.transmission
    self.modules.nixos.slskd
  ];

  swarselsystems.proxyHost = config.node.name;

}
// lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 6;
    vcpu = 4;
  };

}
