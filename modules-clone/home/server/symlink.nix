{ self, lib, config, ... }:
{
  options.swarselmodules.server.dotfiles = lib.mkEnableOption "server dotfiles settings";
  config = lib.mkIf config.swarselmodules.server.dotfiles {
    home.file = {
      "init.el" = lib.mkForce {
        source = self + /files/emacs/server.el;
        target = ".emacs.d/init.el";
      };
    };
  };
}
