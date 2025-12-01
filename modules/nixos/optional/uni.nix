{ self, config, ... }:
{
  config = {

    home-manager.users."${config.swarselsystems.mainUser}" = {
      imports = [
        "${self}/modules/home/optional/work.nix"
      ];
    };
  };
}
