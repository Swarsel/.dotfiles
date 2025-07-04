{ self, inputs, config, lib, outputs, globals, nodes, minimal, ... }:
let
  inherit (config.swarselsystems) mainUser;
in
{
  options.swarselsystems.modules.home-manager = lib.mkEnableOption "home-manager";
  config = lib.mkIf config.swarselsystems.modules.home-manager {
    home-manager = lib.mkIf config.swarselsystems.withHomeManager {
      useGlobalPkgs = true;
      useUserPackages = true;
      verbose = true;
      users."${mainUser}".imports = [
        "${self}/profiles/home"
        "${self}/modules/home"
      ];
      sharedModules = [
        inputs.nix-index-database.hmModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
        {
          home.stateVersion = lib.mkDefault config.system.stateVersion;
        }
      ];
      extraSpecialArgs = { inherit (inputs) self nixgl; inherit inputs outputs globals nodes minimal; };
    };
  };
}
