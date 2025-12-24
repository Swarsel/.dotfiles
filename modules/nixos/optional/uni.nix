{ self, config, withHomeManager, ... }:
{
  config = { } // lib.optionalAttrs withHomeManager {

    home-manager.users."${config.swarselsystems.mainUser}" = {
      imports = [
        "${self}/modules/home/optional/work.nix"
      ];
    };
  };
}
