{ lib, inputs, ... }:
let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  workUser = lib.swarselsystems.getSecret "${secretsDirectory}/work/work-user";
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
