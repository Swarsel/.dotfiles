{
  flake.modules.homeManager.emacs-init =
    { lib, ... }:
    let
      lspNixdConfig = ''
        (setq lsp-nix-nixd-server-path "nixd"
              lsp-nix-nixd-formatting-command [ "nixfmt" ]
              lsp-nix-nixd-nixpkgs-expr "import (builtins.getFlake \"/home/swarsel/.dotfiles\").inputs.nixpkgs { }"
              lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options"
              lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options.home-manager.users.type.getSubOptions []"
              )
      '';
    in
    {
      config.programs.emacs.init.usePackage = {
        nix-mode = {
          enable = true;
          after = [ "lsp-mode" ];
          mode = lib.mkForce [ ];
          hook = [ "(nix-mode . lsp-deferred)" ];
          custom = {
            lsp-disabled-clients = "'((nix-mode . nix-nil))";
          };
          config = lspNixdConfig;
        };

        nix-ts-mode = {
          enable = true;
          after = [ "lsp-mode" ];
          mode = [
            ''"\\.nix\\'"''
            ''"\\.nix\\.enc\\'"''
          ];
          hook = [ "(nix-ts-mode . lsp-deferred)" ];
          custom = {
            lsp-disabled-clients = "'((nix-ts-mode . nix-nil))";
          };
          config = lspNixdConfig;
        };
      };
    };
}
