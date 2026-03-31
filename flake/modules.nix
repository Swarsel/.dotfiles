{ self, ... }:
{
  flake = _:
    let
      inherit (self.outputs) lib;
    in
    {
      nixosModules.default = import "${self}/modules/nixos" { inherit lib; };
      homeModules = import "${self}/modules/home" { inherit lib; };
    };
}
