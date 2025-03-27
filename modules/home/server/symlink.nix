{ self, lib, ... }:
{
  home.file = {
    "init.el" = lib.mkForce {
      source = self + /programs/emacs/server.el;
      target = ".emacs.d/init.el";
    };
  };
}
