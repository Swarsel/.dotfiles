{
  flake.modules.homeManager.emacs-init =
    { lib, pkgs, ... }:
    {
      config.programs.emacs.init.usePackage = {
        eglot = {
          config = ''
            (add-to-list 'eglot-server-programs
                         '((nix-mode nix-ts-mode)
                           . ("env" "NIX_CONFIG=plugin-files = ${
                             pkgs.nix-plugins.override { nixComponents = pkgs.nixVersions.latest.libs; }
                           }/lib/nix/plugins" "nixd")))
          '';
          init = ''
            (setq-default eglot-workspace-configuration
                          '(:nixd (:nixpkgs (:expr "import (builtins.getFlake \"/home/swarsel/.dotfiles\").inputs.nixpkgs { }")
                                   :formatting (:command ["pedantix"])
                                   :options (:nixos (:expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options")
                                             :home-manager (:expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options.home-manager.users.valueMeta.attrs.swarsel.configuration.options")
                                             :flake-parts (:expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").debug.options")))))
          '';
        };

        nix-mode = {
          enable = true;
          defer = true;
          mode = lib.mkForce [ ];
        };

        nix-ts-mode = {
          enable = true;
          mode = [
            ''"\\.nix\\'"''
            ''"\\.nix\\.enc\\'"''
          ];
        };
      };
    };
}
