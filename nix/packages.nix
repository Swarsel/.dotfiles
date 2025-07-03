{ self, ... }:
{
  flake = _:
    let
      inherit (self.outputs) lib;
    in
    {
      packages = lib.swarselsystems.forEachLinuxSystem (pkgs: import "${self}/pkgs" { inherit self lib pkgs; });
    };
}
