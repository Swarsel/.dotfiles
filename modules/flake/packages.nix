{ self, ... }:
{
  flake =
    let
      inherit (self.outputs) lib;
    in
    {
      packages = lib.swarselsystems.forEachLinuxSystem (
        pkgs: import "${self}/pkgs/flake" { inherit self lib pkgs; }
      );
    };

  imports = [
    (
      { lib, flake-parts-lib, ... }:
      flake-parts-lib.mkTransposedPerSystemModule {
        file = ./packages.nix;
        name = "pkgs";
        option = lib.mkOption {
          type = lib.types.unspecified;
        };
      }
    )
  ];

  perSystem =
    { pkgs, system, ... }:
    {
      inherit pkgs;
      # see https://flake.parts/module-arguments.html?highlight=modulewith#persystem-module-parameters
      _module.args.pkgs = self.swarselsystemsLib.pkgsFor.${system};
    };
}
