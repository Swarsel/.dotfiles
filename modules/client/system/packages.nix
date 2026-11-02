{
  flake.modules = {
    homeManager = {
      cli-tools = { pkgs, ... }: {
        swarselsystems.enabledHomeModules = [ "cli-tools" ];
        home.packages = with pkgs; [
          vim
          util-linux
          findutils
          fd
          unzip
          gnutar
          psmisc
          lsof
          sops
          ssh-to-age
          nvd
          nix-output-monitor
          nixfmt
          deadnix
          statix
          nix-tree
          nix-diff
        ];
      };
      packages =
        {
          self,
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [ self.modules.homeManager.cli-tools ];
          config = {
            swarselsystems.enabledHomeModules = [ "packages" ];
            home.packages =
              with pkgs;
              [
                (nixpkgs-review.override { nix = config.nix.package; })
                libgsf
                nautilus
                wl-clipboard
                wl-mirror
              ]
              ++ lib.optionals (config.swarselsystems.isFullBuild && pkgs.stdenv.hostPlatform.isx86_64) [
                cura-appimage
                zoom-us
              ]
              ++ lib.optionals config.swarselsystems.isFullBuild [
                calibre
                simple-scan
                mgba
                uv
                croc
                gimp
                inkscape
                libreoffice-qt
                xournalpp
                hugo

                ffmpeg_7-full
                texliveFull
                unrar
                zbar # qr codes

                wf-recorder

                adwaita-icon-theme
                cantarell-fonts
                nerd-fonts.symbols-only
              ];
          };
        };
    };
    nixos.packages =
      {
        config,
        lib,
        pkgs,
        minimal,
        ...
      }:
      {
        config.environment.systemPackages =
          with pkgs;
          lib.optionals (!minimal) (
            [
              just
              yubikey-manager
            ]
            ++ lib.optionals (config.swarselsystems.isFullBuild && pkgs.stdenv.hostPlatform.isx86_64) [
              # ledger packages
              ledger-live-desktop
            ]
            ++ lib.optionals config.swarselsystems.isFullBuild [
              pciutils
              pre-commit
              qmk
              usbutils
            ]
          )
          ++ lib.optionals minimal [
            networkmanager
            curl
            git
            gnupg
            rsync
            ssh-to-age
            sops
            vim
            just
            sbctl
          ];
      };
  };
}
