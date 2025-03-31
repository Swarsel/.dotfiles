{ inputs, config, lib, ... }:
{
  options.swarselsystems.modules.home-managerExtra = lib.mkEnableOption "home-manager extras for non-chaostheatre";
  config = lib.mkIf config.swarselsystems.modules.home-managerExtra {
    home-manager = lib.mkIf config.swarselsystems.withHomeManager {
      extraSpecialArgs = { inherit (inputs) nix-secrets nixgl; };
    };
  };
}
