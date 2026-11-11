# adapted from https://github.com/oddlama/nix-config/blob/main/nix/globals.nix
{ self, inputs, ... }:
{

  flake-file.inputs.topologyPrivate.url = "./files/topology/public";

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
              (self.swarselsystemsLib.importEncrypted ../../secrets/repo/globals.nix.enc)
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
