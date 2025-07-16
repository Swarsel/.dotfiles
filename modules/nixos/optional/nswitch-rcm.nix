{ lib, config, pkgs, ... }:
{
  options.swarselmodules.optional.nswitch-rcm = lib.mkEnableOption "optional nswitch-rcm settings";
  config = lib.mkIf config.swarselmodules.optional.nswitch-rcm {
    services.nswitch-rcm = {
      enable = true;
      package = pkgs.fetchurl {
        url = "https://github.com/Atmosphere-NX/Atmosphere/releases/download/1.3.2/fusee.bin";
        hash = "sha256-5AXzNsny45SPLIrvWJA9/JlOCal5l6Y++Cm+RtlJppI=";
      };
    };
  };
}
