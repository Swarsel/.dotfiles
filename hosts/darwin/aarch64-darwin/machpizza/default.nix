{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.repo.secrets.local) workUser;
in
{
  imports = [
    self.modules.darwin.profile-darwin
  ];

  users.users.${workUser}.home = "/home/${workUser}";
  services.karabiner-elements.enable = true;

  home-manager.users.${workUser} = {
    swarselsystems = {
      isBtrfs = false;
      isLaptop = true;
      mainUser = workUser;
    };
    home.username = lib.mkForce workUser;
  };

  system.primaryUser = workUser;
}
