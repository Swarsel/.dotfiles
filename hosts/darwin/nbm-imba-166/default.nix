{ self, inputs, outputs, ... }:
let
  profilesPath = "${self}/profiles";
in
{
  imports = [
    "${profilesPath}/darwin/common/nixos"

    inputs.home-manager.darwinModules.home-manager
    {
      home-manager.users."leon.schwarzaeugl".imports = [
        "${profilesPath}/darwin/common/home"
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


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
