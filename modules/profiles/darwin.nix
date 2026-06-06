{
  flake.modules.darwin.profile-darwin = { self, ... }: {
    imports = [
      self.modules.darwin.settings
      self.modules.darwin.home-manager
      self.modules.generic.meta
      self.modules.generic.globals
      self.modules.generic.pii
    ];
  };
}
