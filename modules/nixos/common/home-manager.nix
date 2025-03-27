{ inputs, config, lib, ... }:
{
  home-manager = lib.mkIf config.swarselsystems.withHomeManager {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit (inputs) self; };
  };
}
