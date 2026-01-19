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
      packages = lib.swarselsystems.forEachLinuxSystem (pkgs: import "${self}/pkgs/flake" { inherit self lib pkgs; });
    };

  perSystem = { pkgs, system, ... }:
    {
      # see https://flake.parts/module-arguments.html?highlight=modulewith#persystem-module-parameters
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;

          permittedInsecurePackages = [
            # matrix
            "olm-3.2.16"
            # sonarr
            "aspnetcore-runtime-wrapped-6.0.36"
            "aspnetcore-runtime-6.0.36"
            "dotnet-sdk-wrapped-6.0.428"
            "dotnet-sdk-6.0.428"
            #
            "SDL_ttf-2.0.11"
          ];
        };
        overlays = [
          self.overlays.default
        ];
      };
      inherit pkgs;
    };
}
