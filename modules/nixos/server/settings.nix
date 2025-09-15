{ lib, config, ... }:
let
  inherit (config.swarselsystems) flakePath;
in
{

  options.swarselmodules.server.general = lib.mkEnableOption "general setting on server";
  options.swarselsystems = {
    shellAliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };
  config = lib.mkIf config.swarselmodules.server.general {

    environment.shellAliases = lib.recursiveUpdate
      {
        nswitch = "cd ${flakePath}; swarsel-deploy $(hostname) switch; cd -;";
        nboot = "cd ${flakePath}; swarsel-deploy $(hostname) boot; cd -;";
        ndry = "cd ${flakePath}; swarsel-deploy $(hostname) dry-activate; cd -;";
      }
      config.swarselsystems.shellAliases;

    nixpkgs.config.permittedInsecurePackages = [
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
}
