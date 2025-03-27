{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "profiles/nixos/server";
  profilesPath = "${self}/profiles";
in
{
  imports = lib.swarselsystems.mkImports importNames "profiles/nixos/server" ++ [
    "${profilesPath}/nixos/common/settings.nix"
    "${profilesPath}/nixos/common/home-manager.nix"
    "${profilesPath}/nixos/common/home-manager-extra.nix"
    "${profilesPath}/nixos/common/xserver.nix"
    "${profilesPath}/nixos/common/gc.nix"
    "${profilesPath}/nixos/common/store.nix"
    "${profilesPath}/nixos/common/time.nix"
    "${profilesPath}/nixos/common/users.nix"
    "${profilesPath}/nixos/common/nix-ld.nix"
    "${profilesPath}/nixos/common/sharedsetup.nix"
    "${profilesPath}/home/common/sharedsetup.nix"
  ];
}
