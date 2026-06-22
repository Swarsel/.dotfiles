{
  self,
  lib,
  config,
  ...
}:
let
  inherit (config.repo.secrets.local) workUser;
in
{
  imports = [
    self.modules.darwin.profile-darwin
  ];

  services.karabiner-elements.enable = true;

  system.primaryUser = workUser;
  users.users.${workUser}.home = "/home/${workUser}";

  home-manager.users.${workUser} = {
    home.username = lib.mkForce workUser;
    swarselsystems = {
      isDarwin = true;
      isLaptop = true;
      isBtrfs = false;
      mainUser = workUser;
      homeDir = "/home/${workUser}";
      flakePath = "/home/${workUser}/.dotfiles";
    };
  };
}
