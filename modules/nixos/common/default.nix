{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/common";
  modulesPath = "${self}/modules";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/common" ++ [
    "${modulesPath}/home/common/sharedsetup.nix"
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "jitsi-meet-1.0.8043"
    "electron-29.4.6"
    "SDL_ttf-2.0.11"
  ];

}
