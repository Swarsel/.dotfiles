{
  flake.modules = {
    nixos.profile-base = { self, lib, ... }: {
      imports = builtins.attrValues (lib.getAttrs [ "meta" "options" "vars" "config-lib" "globals" ] self.modules.generic) ++ [
        self.modules.nixos.dns
        self.modules.nixos.nftables
        self.modules.nixos.nodes
        self.modules.nixos.topology
        self.modules.nixos.id
      ];
    };

    homeManager.profile-base = { self, lib, ... }: {
      imports = builtins.attrValues (lib.getAttrs [ "meta" "options" "vars" "config-lib" ] self.modules.generic) ++ [
        self.modules.homeManager.sharedoptions
      ];
    };
  };
}
