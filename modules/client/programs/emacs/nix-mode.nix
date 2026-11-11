{
  flake.modules.homeManager.emacs-init =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      flake = ''(builtins.getFlake \"${config.swarselsystems.flakePath}\")'';
      nixosOptions = "${flake}.nixosConfigurations.${config.node.name}.options";
    in
    {
      config.programs.emacs.init.usePackage = {
        eglot = {
          config = ''
            (add-to-list 'eglot-server-programs
                         '((nix-mode nix-ts-mode)
                           . ("${lib.getExe pkgs.nixd}")))
          '';
          init = ''
            (setq-default eglot-workspace-configuration
                          '(:nixd (:nixpkgs (:expr "import ${flake}.inputs.nixpkgs { }")
                                   :formatting (:command ["pedantix"])
                                   :options (:nixos (:expr "${nixosOptions}")
                                             :home-manager (:expr "${nixosOptions}.home-manager.users.valueMeta.attrs.${config.swarselsystems.mainUser}.configuration.options")
                                             :flake-parts (:expr "${flake}.debug.options")))))
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
