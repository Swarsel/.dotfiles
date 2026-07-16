{ self, ... }:
{
  flake = {
    homeModules = self.modules.homeManager.profile-base;
    nixosModules.default = self.modules.nixos.profile-base;
  };
}
