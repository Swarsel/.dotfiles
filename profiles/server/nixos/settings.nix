{ lib, config, ... }:
{
  environment.shellAliases = lib.recursiveUpdate
    {
      npswitch = "cd ${config.swarselsystems.flakePath}; git pull; sudo nixos-rebuild --flake .#$(hostname) switch --impure; cd -;";
      nswitch = "cd ${config.swarselsystems.flakePath}; sudo nixos-rebuild --flake .#$(hostname) switch --impure; cd -;";
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
  ];

}
