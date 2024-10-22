{ inputs, outputs, config, pkgs, lib, ... }:
{

  imports = [
    inputs.home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users."leon.schwarzaeugl".imports = [
        ../../common/home/emacs.nix
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);

  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs = {
    inherit (outputs) overlays;
    config = {
      allowUnfree = true;
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.karabiner-elements.enable = true;

  home-manager.users."leon.schwarzaeugl".swarselsystems = {
    isDarwin = true;
    isLaptop = true;
    isNixos = false;
    isBtrfs = false;
  };

  system.stateVersion = 4;

}
