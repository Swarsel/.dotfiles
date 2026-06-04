{ inputs, lib, ... }:
{
  flake-file.inputs.nswitch-rcm-nix.url = "github:Swarsel/nswitch-rcm-nix";

  imports = lib.optionals (inputs ? nswitch-rcm-nix) [
    inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
    ({ pkgs, ... }: {
      services.nswitch-rcm = {
        enable = true;
        package = pkgs.fetchurl {
          url = "https://github.com/Atmosphere-NX/Atmosphere/releases/download/1.3.2/fusee.bin";
          hash = "sha256-5AXzNsny45SPLIrvWJA9/JlOCal5l6Y++Cm+RtlJppI=";
        };
      };
    })
  ];
}
