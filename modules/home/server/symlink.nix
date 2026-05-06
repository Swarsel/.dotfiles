{ self, lib, ... }:
{
  config = {
    swarselsystems.enabledHomeModules = [ "server-dotfiles" ];
    home.file = {
      "init.el" = lib.mkForce {
        source = self + /files/emacs/server.el;
        target = ".emacs.d/init.el";
      };
    };
  };
}
