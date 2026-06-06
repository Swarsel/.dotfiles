{ self, ... }:
{
  flake = {
    nixosModules.default = self.modules.nixos.profile-base;
    homeModules = self.modules.homeManager.profile-base;
  };
}
