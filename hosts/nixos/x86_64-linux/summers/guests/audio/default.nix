{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos/server/navidrome.nix"
    "${self}/modules/nixos/server/spotifyd.nix"
    "${self}/modules/nixos/server/mpd.nix"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };

} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 4;
    vcpu = 2;
  };

}
