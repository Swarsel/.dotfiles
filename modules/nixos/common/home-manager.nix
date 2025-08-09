{ self, inputs, config, lib, outputs, globals, options, nodes, minimal, configName, ... }:
{
  options.swarselmodules.home-manager = lib.mkEnableOption "home-manager";
  config = lib.mkIf config.swarselmodules.home-manager {
    home-manager = lib.mkIf config.swarselsystems.withHomeManager {
      useGlobalPkgs = true;
      useUserPackages = true;
      verbose = true;
      users.${config.swarselsystems.mainUser}.imports = [
        inputs.nix-index-database.homeModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
        # inputs.stylix.homeModules.stylix
        {
          imports = [
            "${self}/profiles/home"
            "${self}/modules/home"
            {
              swarselprofiles = {
                minimal = lib.mkIf minimal true;
              };
            }
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
