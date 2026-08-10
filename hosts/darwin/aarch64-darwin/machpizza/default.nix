{
  self,
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

  networking.hostName = "machpizza";

  users.users.${workUser}.home = "/Users/${workUser}";
  services.karabiner-elements.enable = false;

  ids.gids.nixbld = 350;

  home-manager.users.${workUser} = {
    swarselsystems = {
      flakePath = "/Users/${workUser}/.dotfiles";
      homeDir = "/Users/${workUser}";
      isBtrfs = false;
      isDarwin = true;
      isLaptop = true;
      mainUser = workUser;
    };
  };

  system.primaryUser = workUser;
}
