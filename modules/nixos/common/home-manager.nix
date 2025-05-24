{ inputs, config, lib, ... }:
{

  options.swarselsystems.modules.home-manager = lib.mkEnableOption "home-manager";
  config = lib.mkIf config.swarselsystems.modules.home-manager {
    home-manager = lib.mkIf config.swarselsystems.withHomeManager {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit (inputs) self; };
    };
  };
}
