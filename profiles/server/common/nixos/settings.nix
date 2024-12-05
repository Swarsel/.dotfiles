{ lib, config, ... }:
{
  environment.shellAliases = lib.recursiveUpdate
    {
      npswitch = "cd ${config.swarselsystems.flakePath}; git pull; sudo nixos-rebuild --flake .#$(hostname) switch --impure; cd -;";
      nswitch = "cd ${config.swarselsystems.flakePath}; sudo nixos-rebuild --flake .#$(hostname) switch --impure; cd -;";
    }
    config.swarselsystems.shellAliases;

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

}
