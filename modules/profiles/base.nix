{
  flake.modules = {
    homeManager.profile-base = { self, lib, ... }: {
      imports =
        builtins.attrValues (lib.getAttrs [ "meta" "options" "config-lib" ] self.modules.generic)
        ++ [
          self.modules.homeManager.sharedoptions
        ];
    };
    nixos.profile-base = { self, lib, ... }: {
      imports =
        builtins.attrValues (lib.getAttrs [ "meta" "options" "config-lib" "globals" ] self.modules.generic)
        ++ [
          self.modules.nixos.dns
          self.modules.nixos.nftables
          self.modules.nixos.nodes
          self.modules.nixos.topology
          self.modules.nixos.id
        ];
    };
  };
}
