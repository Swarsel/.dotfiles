{ self, ... }:
{
  home.file = {
    "init.el" = {
      source = self + /programs/emacs/server.el;
      target = ".emacs.d/init.el";
    };
  };
}
