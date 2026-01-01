# adapted from https://github.com/oddlama/nix-config/blob/main/nix/globals.nix
{ self, inputs, ... }:
{

  imports = [
    (
      { lib, flake-parts-lib, ... }:
      flake-parts-lib.mkTransposedPerSystemModule {
        name = "globals";
        file = ./globals.nix;
        option = lib.mkOption {
          type = lib.types.unspecified;
        };
      }
    )
  ];
  perSystem = { lib, pkgs, ... }:
    {
      globals =
        let
          globalsSystem = lib.evalModules {
            prefix = [ "globals" ];
            specialArgs = {
              inherit (pkgs) lib;
              inherit (self.outputs) nodes;
              inherit inputs;
            };
            modules = [
              ../modules/nixos/common/globals.nix
              (
                { lib, ... }:
                let
                  sopsImportEncrypted =
                    assert lib.assertMsg (builtins ? extraBuiltins.sopsImportEncrypted)
                      "The extra builtin 'sopsImportEncrypted' is not available, so repo.secrets cannot be decrypted. Did you forget to add nix-plugins and point it to `./nix/extra-builtins.nix` ?";
                    builtins.extraBuiltins.sopsImportEncrypted;
                in

                {
                  imports = [
                    (sopsImportEncrypted ../secrets/repo/globals.nix.enc)
                  ];

                }
              )
              (
                { lib, ... }:
                {
                  globals = lib.mkMerge (
                    lib.concatLists (
                      lib.flip lib.mapAttrsToList self.outputs.nodes (
                        name: cfg:
                          builtins.addErrorContext "while aggregating globals from nixosConfigurations.${name} into flake-level globals:" cfg.config._globalsDefs
                      )
                    )
                  );
                }
              )
            ];
          };
        in
        {
          inherit (globalsSystem.config.globals)
            domains
            services
            networks
            hosts
            user
            root
            general
            ;
        };
    };
}
