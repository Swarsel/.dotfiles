{ inputs, config, lib, ... }:
{
  home-manager = lib.mkIf config.swarselsystems.withHomeManager {
    extraSpecialArgs = { inherit (inputs) nix-secrets; };
  };
}
