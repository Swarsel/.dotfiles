{ self, inputs, ... }:
{
  imports = [
    (
      { lib, flake-parts-lib, ... }:
      flake-parts-lib.mkTransposedPerSystemModule {
        name = "pkgs";
        file = ./packages.nix;
        option = lib.mkOption {
          type = lib.types.unspecified;
        };
      }
    )
  ];
  flake = _:
    let
      inherit (self.outputs) lib;
    in
    {
      packages = lib.swarselsystems.forEachLinuxSystem (pkgs: import "${self}/pkgs" { inherit self lib pkgs; });
    };

  perSystem = { pkgs, system, ... }:
    {
      # see https://flake.parts/module-arguments.html?highlight=modulewith#persystem-module-parameters
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          self.overlays.default
        ];
      };
      inherit pkgs;
    };
}
