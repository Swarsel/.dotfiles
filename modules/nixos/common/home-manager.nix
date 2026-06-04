{ self, inputs, config, lib, homeLib, outputs, globals, nodes, minimal, configName, arch, type, ... }:
let
  inherit (config.swarselsystems) isServer isMicroVM;
in
{
  imports = [
    "${self}/modules/nixos/common/home-manager-secrets.nix"
  ];
  config = {
    home-manager = lib.mkIf (!isServer && !isMicroVM) {
      useGlobalPkgs = true;
      useUserPackages = true;
      verbose = true;
      backupFileExtension = "hm-bak";
      overwriteBackup = true;
      users.${config.swarselsystems.mainUser}.imports = [
        {
          imports = [
            "${self}/modules/home"
          ] ++ lib.optionals minimal [
            "${self}/profiles/home/minimal"
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
