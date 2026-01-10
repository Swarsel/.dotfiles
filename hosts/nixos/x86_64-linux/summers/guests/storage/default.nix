{ self, lib, minimal, ... }:
{
  imports = [
    "${self}/profiles/nixos/microvm"
    "${self}/modules/nixos"
  ];

  swarselsystems = {
    isMicroVM = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
    server = {
      wireguard.interfaces = {
        wgHome = {
          isClient = true;
          serverName = "hintbooth";
        };
        wgProxy = {
          isClient = true;
          serverName = "twothreetunnel";
        };
      };
    };
  };


} // lib.optionalAttrs (!minimal) {

  microvm = {
    mem = 1024 * 2;
    vcpu = 2;
  };

  swarselprofiles = {
    microvm = true;
  };

  swarselmodules.server = {
    nfs = true;
    syncthing = true;
  };

}
