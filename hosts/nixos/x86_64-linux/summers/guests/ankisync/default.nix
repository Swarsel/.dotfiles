{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos/server/ankisync.nix"
    "${self}/modules/nixos/server/invidious-companion.nix"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 1;
    vcpu = 1;
  };

}
