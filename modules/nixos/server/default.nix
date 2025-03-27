{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/server";
  modulesPath = "${self}/modules";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/server" ++ [
    "${modulesPath}/nixos/common/settings.nix"
    "${modulesPath}/nixos/common/home-manager.nix"
    "${modulesPath}/nixos/common/home-manager-extra.nix"
    "${modulesPath}/nixos/common/xserver.nix"
    "${modulesPath}/nixos/common/gc.nix"
    "${modulesPath}/nixos/common/store.nix"
    "${modulesPath}/nixos/common/time.nix"
    "${modulesPath}/nixos/common/users.nix"
    "${modulesPath}/nixos/common/nix-ld.nix"
    "${modulesPath}/nixos/common/sharedsetup.nix"
    "${modulesPath}/home/common/sharedsetup.nix"
  ];
}
