# adapted from https://github.com/oddlama/nix-config/blob/main/nix/globals.nix
{ self, inputs, ... }:
{

  flake-file.inputs = {
    repoSecrets.url = "./secrets/repo";
    topologyPrivate.url = "./files/topology/public";
  };

  imports = [
    (
      { lib, flake-parts-lib, ... }:
      flake-parts-lib.mkTransposedPerSystemModule {
        file = ./globals.nix;
        name = "globals";
        option = lib.mkOption {
          type = lib.types.unspecified;
        };
      }
    )
  ];

  perSystem =
    { lib, pkgs, ... }:
    {
      globals =
        let
          globalsSystem = lib.evalModules {
            modules = [
              self.modules.generic.globals
              (
                { lib, ... }:
                let
                  sopsImportEncrypted =
                    assert lib.assertMsg (builtins ? extraBuiltins.sopsImportEncrypted)
                      "The extra builtin 'sopsImportEncrypted' is not available, so repo.secrets cannot be decrypted. Did you forget to add nix-plugins and point it to `./files/nix/extra-builtins.nix` ?";
                    builtins.extraBuiltins.sopsImportEncrypted;
                  globalsFile = inputs.repoSecrets.globals;
                in

                {
                  imports = [
                    (
                      if lib.hasSuffix ".enc" (toString globalsFile) then sopsImportEncrypted globalsFile else globalsFile
                    )
                  ];

                }
              )
            ]
            ++ lib.optionals (!(inputs.repoSecrets.isDemo or false)) [
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
            prefix = [ "globals" ];
            specialArgs = {
              inherit (pkgs) lib;
              inherit (self.outputs) nodes;
              inherit inputs;
              inherit (inputs.topologyPrivate) topologyPrivate;
            };
          };
        in
        {
          inherit (globalsSystem.config.globals)
            dns
            domains
            general
            hosts
            monitoring
            networks
            root
            services
            user
            wireguard
            ;
        };
    };
}
