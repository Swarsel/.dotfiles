{ lib, ... }:
let
  inherit (config.repo.secrets.local) workUser;
in
{

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.karabiner-elements.enable = true;

  home-manager.users.workUser.home = {
    username = lib.mkForce workUser;
    swarselsystems = {
      isDarwin = true;
      isLaptop = true;
      isNixos = false;
      isBtrfs = false;
      mainUser = workUser;
      homeDir = "/home/${workUser}";
      flakePath = "/home/${workUser}/.dotfiles";
    };
  };
}
