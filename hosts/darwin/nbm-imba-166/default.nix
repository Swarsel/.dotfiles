{ lib, ... }:
{

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.karabiner-elements.enable = true;

  home-manager.users."leon.schwarzaeugl".home = {
    username = lib.mkForce "leon.schwarzaeugl";
    swarselsystems = {
      isDarwin = true;
      isLaptop = true;
      isNixos = false;
      isBtrfs = false;
    };
  };
}
