# adapted from https://github.com/oddlama/nix-config/blob/main/nix/globals.nix
{ self, inputs, ... }:
{

  flake-file.inputs = {
    topologyPrivate.url = "./files/topology/public";
    repoSecrets.url = "./secrets/repo";
  };

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
  perSystem =
    { lib, pkgs, ... }:
    {
      globals =
        let
          globalsSystem = lib.evalModules {
            prefix = [ "globals" ];
            specialArgs = {
              inherit (pkgs) lib;
              inherit (self.outputs) nodes;
              inherit inputs;
              inherit (inputs.topologyPrivate) topologyPrivate;
            };
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
            wireguard
            dns
            monitoring
            ;
        };
    };
}
