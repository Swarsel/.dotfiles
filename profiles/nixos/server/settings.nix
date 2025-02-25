{ lib, config, ... }:
{
  environment.shellAliases = lib.recursiveUpdate
    {
      npswitch = "cd ${config.swarselsystems.flakePath}; git pull; sudo nixos-rebuild --flake .#$(hostname) switch; cd -;";
      nswitch = "sudo nixos-rebuild --flake ${config.swarselsystems.flakePath}#$(hostname) switch;";
      npiswitch = "cd ${config.swarselsystems.flakePath}; git pull; sudo nixos-rebuild --flake .#$(hostname) switch --impure; cd -;";
      nipswitch = "cd ${config.swarselsystems.flakePath}; git pull; sudo nixos-rebuild --flake .#$(hostname) switch --impure; cd -;";
      niswitch = "sudo nixos-rebuild --flake ${config.swarselsystems.flakePath}#$(hostname) switch --impure;";
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

}
