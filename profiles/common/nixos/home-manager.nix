{ inputs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = inputs; # used mainly for inputs.self
  };
}
