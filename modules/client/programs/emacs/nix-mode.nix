{
  flake.modules.homeManager.emacs-init =
    { lib, ... }:
    let
      lspNixdConfig = ''
        (setq lsp-nix-nixd-server-path "nixd"
              lsp-nix-nixd-formatting-command [ "pedantix" ]
              lsp-nix-nixd-nixpkgs-expr "import (builtins.getFlake \"/home/swarsel/.dotfiles\").inputs.nixpkgs { }"
              lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options"
              lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options.home-manager.users.type.getSubOptions []"
              )
      '';
    in
    {
      config.programs.emacs.init.usePackage = {
        nix-mode = {
          config = lspNixdConfig;
          enable = true;
          after = [ "lsp-mode" ];
          custom = {
            lsp-disabled-clients = "'((nix-mode . nix-nil))";
          };
          hook = [ "(nix-mode . lsp-deferred)" ];
          mode = lib.mkForce [ ];
        };

        nix-ts-mode = {
          config = lspNixdConfig;
          enable = true;
          after = [ "lsp-mode" ];
          custom = {
            lsp-disabled-clients = "'((nix-ts-mode . nix-nil))";
          };
          hook = [ "(nix-ts-mode . lsp-deferred)" ];
          mode = [
            ''"\\.nix\\'"''
            ''"\\.nix\\.enc\\'"''
          ];
        };
      };
    };
}
