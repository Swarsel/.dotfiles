{ self, ... }:
{
  imports = [
    "${self}/modules/home/common/settings.nix"
    "${self}/modules/home/common/sharedsetup.nix"
  ];
}
