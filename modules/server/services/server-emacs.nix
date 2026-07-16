{
  flake.modules = {
    homeManager.server-emacs =
      { self, lib, ... }:
      {
        config = {
          swarselsystems.enabledHomeModules = [ "server-dotfiles" ];
          home.file."init.el" = lib.mkForce {
            source = self + /files/emacs/server.el;
            target = ".emacs.d/init.el";
          };
        };
      };
    nixos.server-emacs =
      { confLib, ... }:
      let
        inherit
          (confLib.gen {
            name = "emacs";
            port = 9812;
          })
          serviceName
          servicePort
          ;
      in
      {
        config = {
          swarselsystems.enabledServerModules = [ "emacs" ];
          services.${serviceName} = {
            enable = true;
            install = true;
            startWithGraphical = false;
          };
          networking.firewall.allowedTCPPorts = [ servicePort ];
        };
      };
  };
}
