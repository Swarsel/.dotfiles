{
  flake.modules.nixos.server-settings =
    { config, lib, ... }:
    let
      inherit (config.swarselsystems) flakePath;
    in
    {

      options.swarselsystems = {
        shellAliases = lib.mkOption {
          default = { };
          type = lib.types.attrsOf lib.types.str;
        };
      };
      config = {
        swarselsystems.enabledServerModules = [ "general" ];
        environment.shellAliases = lib.recursiveUpdate {
          nboot = "cd ${flakePath}; swarsel-deploy $(hostname) boot; cd -;";
          ndry = "cd ${flakePath}; swarsel-deploy $(hostname) dry-activate; cd -;";
          nswitch = "cd ${flakePath}; swarsel-deploy $(hostname) switch; cd -;";
          ntest = "cd ${flakePath}; swarsel-deploy $(hostname) test; cd -;";
        } config.swarselsystems.shellAliases;
        nixpkgs.config = lib.mkIf (!config.swarselsystems.isMicroVM) {
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
      };
    }

  ;
}
