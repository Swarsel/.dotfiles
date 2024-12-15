{ inputs, config, lib, ... }:
{
  home-manager = lib.mkIf config.swarselsystems.withHomeManager {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = inputs; # used mainly for inputs.self
  };
}
