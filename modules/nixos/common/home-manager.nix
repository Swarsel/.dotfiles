{ self, inputs, config, lib, outputs, globals, nodes, minimal, configName, ... }:
{
  options.swarselsystems.modules.home-manager = lib.mkEnableOption "home-manager";
  config = lib.mkIf config.swarselsystems.modules.home-manager {
    home-manager = lib.mkIf config.swarselsystems.withHomeManager {
      useGlobalPkgs = true;
      useUserPackages = true;
      verbose = true;
      users.swarsel.imports = [
        inputs.nix-index-database.hmModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
        # inputs.stylix.homeModules.stylix
        {
          imports = [
            "${self}/profiles/home"
            "${self}/modules/home"
            # "${self}/modules/nixos/common/pii.nix"
            # "${self}/modules/nixos/common/meta.nix"
          ];
          # node = {
          #   secretsDir = if (!config.swarselsystems.isNixos) then ../../../hosts/home/${configName}/secrets else ../../../hosts/nixos/${configName}/secrets;
          # };
          home.stateVersion = lib.mkDefault config.system.stateVersion;
        }
      ];
      extraSpecialArgs = { inherit (inputs) self nixgl; inherit inputs outputs globals nodes minimal configName; };
    };
  };
}
