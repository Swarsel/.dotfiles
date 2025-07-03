{ self, lib, config, ... }:
{
  options.swarselsystems.modules.server.dotfiles = lib.mkEnableOption "server dotfiles settings";
  config = lib.mkIf config.swarselsystems.modules.server.dotfiles {
    home.file = {
      "init.el" = lib.mkForce {
        source = self + /files/emacs/server.el;
        target = ".emacs.d/init.el";
      };
    };
  };
}
