{ self, inputs, config, lib, homeLib, outputs, globals, nodes, minimal, configName, arch, type, withHomeManager, ... }:
{
  options.swarselmodules.home-manager = lib.mkEnableOption "home-manager";
  config = lib.mkIf config.swarselmodules.home-manager {
    home-manager = lib.mkIf withHomeManager {
      useGlobalPkgs = true;
      useUserPackages = true;
      verbose = true;
      backupFileExtension = "hm-bak";
      overwriteBackup = true;
      users.${config.swarselsystems.mainUser}.imports = [
        inputs.nix-index-database.homeModules.nix-index
        # inputs.sops.homeManagerModules.sops # this is not needed!! we add these secrets in nixos scope
        inputs.spicetify-nix.homeManagerModules.default
        inputs.swarsel-nix.homeModules.default
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
      extraSpecialArgs = {
        inherit (inputs) self nixgl;
        inherit inputs outputs globals nodes minimal configName arch type;
        lib = homeLib;
      };
    };
  };
}
