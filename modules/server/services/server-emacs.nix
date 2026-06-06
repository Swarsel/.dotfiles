{
  flake.modules = {
    nixos.server-emacs =
      { confLib, ... }:
      let
        inherit (confLib.gen { name = "emacs"; port = 9812; }) servicePort serviceName;
      in
      {
        config = {
          swarselsystems.enabledServerModules = [ "emacs" ];

          networking.firewall.allowedTCPPorts = [ servicePort ];

          services.${serviceName} = {
            enable = true;
            install = true;
            startWithGraphical = false;
          };
        };
      };

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
  };
}
