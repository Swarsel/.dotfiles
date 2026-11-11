{
  flake.modules = {
    homeManager.zsh =
      {
        root,
        config,
        lib,
        pkgs,
        arch,
        confLib,
        globals,
        minimal,
        nixosConfig ? null,
        ...
      }:
      let
        inherit (config.swarselsystems) flakePath homeDir;
        isNixos = nixosConfig != null;
        fzf = lib.getExe pkgs.fzf;
      in
      {
        options.swarselsystems.shellAliases = lib.mkOption {
          default = { };
          type = lib.types.attrsOf lib.types.str;
        };
        config = {
          swarselsystems = {
            enabledHomeModules = [ "zsh" ];
            homeSopsSecrets = {
              croc-password.rekey.keyPrefix = confLib.static.sharedSecrets.clients;
              github-nixpkgs-review-token.rekey.keyPrefix = confLib.static.sharedSecrets.clients;
            };
          };
          programs.zsh = {
            enable = true;
          }
          // lib.optionalAttrs (!minimal) {
            autocd = false;
            autosuggestion.enable = true;
            cdpath = [
              "~/.dotfiles"
              # "~/Documents/GitHub"
            ];
            defaultKeymap = "emacs";
            dirHashes = {
              dl = "$HOME/Downloads";
              gh = "$HOME/Documents/GitHub";
            };
            enableCompletion = true;
            history = {
              append = true;
              expireDuplicatesFirst = true;
              ignoreDups = true;
              ignoreSpace = true;
              path = "${config.home.homeDirectory}/.histfile";
              save = 100000;
              size = 100000;
            };
            historySubstringSearch = {
              enable = true;
              searchDownKey = "^[OB";
              searchUpKey = "^[OA";
            };
            initContent = ''
              my-word-widget() {
                local WORDCHARS=$WORDCHARS
                WORDCHARS="''${WORDCHARS//:}"
                WORDCHARS="''${WORDCHARS//\/}"
                WORDCHARS="''${WORDCHARS//.}"
                zle ''${WIDGET#my-}
              }
              zle -N my-forward-word my-word-widget
              zle -N my-backward-word my-word-widget
              zle -N my-backward-delete-word my-word-widget

              # ctrl + right
              bindkey "^[[1;5C" my-forward-word

              # shift + right
              bindkey "^[[1;2C" forward-word

              # ctrl + left
              bindkey "^[[1;5D" my-backward-word

              # shift + left
              bindkey "^[[1;2D" backward-word

              # ctrl + del
              bindkey '^H' my-backward-delete-word

              cdr() {
                local target=$({ find ${
                  lib.escapeShellArgs (
                    lib.attrValues (
                      lib.filterAttrs (name: _: lib.hasPrefix "DOCUMENT_DIR_" name) config.systemd.user.sessionVariables
                    )
                  )
                } -maxdepth 1; print ${flakePath}; } | ${fzf})
                [[ -n $target ]] && cd $target
              }

              cdb() {
                local branch=$(git branch --format='%(refname:short)' | ${fzf})
                [[ -n $branch ]] && git checkout $branch
              }

              cdw() {
                local target=$(git worktree list | ${fzf} | cut -d' ' -f1)
                [[ -n $target ]] && cd $target
              }

              bak() {
                cp -r $1 $1.bak
              }

              t2ts() {
                date -d $1 +%s
              }

              ts2t() {
                date -d @$1 2>/dev/null || date -r $1
              }

              sshrm() {
                local cmd=$(fc -lnm 'ssh *' 1 | tail -n 1)
                local host=$(command ssh -G ''${=cmd#ssh } 2>/dev/null | sed -n 's/^hostname //p')
                [[ -n $host ]] && ssh-keygen -R $host
              }
            '';
            plugins = [
              # {
              #   name = "fzf-tab";
              #   src = pkgs.zsh-fzf-tab;
              # }
            ];
            sessionVariables = lib.mkIf (!config.swarselsystems.isPublic) {
              CROC_PASS = "$(cat ${confLib.getConfig.sops.secrets.croc-password.path})";
              CROC_RELAY = globals.services.croc.domain;
              GITHUB_TOKEN = "$(cat ${confLib.getConfig.sops.secrets.github-nixpkgs-review-token.path})";
              QT_QPA_PLATFORM_PLUGIN_PATH = "${pkgs.qt5.qtbase.bin}/lib/qt-${pkgs.qt5.qtbase.version}/plugins";
              # QTWEBENGINE_CHROMIUM_FLAGS = "--no-sandbox";
            };
            shellAliases = lib.recursiveUpdate {
              config = "git --git-dir=$HOME/.cfg/ --work-tree=$HOME";
              boot-diff = "nix store diff-closures /run/*-system";
              build-iso = "nix build --print-out-paths .#live-iso";
              build-topology = "nix build --override-input topologyPrivate ${root "files/topology/private"} ${flakePath}#topology.${arch}.config.output";
              build-topology-dev = "nix build --show-trace --override-input nix-topology ${homeDir}/Documents/Private/nix-topology --override-input topologyPrivate ${root "files/topology/private"} ${flakePath}#topology.${arch}.config.output";
              c = "git --git-dir=$FLAKE/.git --work-tree=$FLAKE/";
              cat-orig = "cat";
              cc = "wl-copy";
              g = "git";
              gen-diff = "nix profile diff-closures --profile /nix/var/nix/profiles/system";
              hmswitch = lib.mkIf (
                !isNixos
              ) "${lib.getExe pkgs.home-manager} --flake ${flakePath}#$(hostname) switch |& nom";
              hotspot = "nmcli connection up local; nmcli device wifi hotspot;";
              lt = "eza -las modified --total-size";
              magit = "emacsclient -nc -e \"(magit-status)\"";
              nb = "nix build";
              nbl = "nix build --builders \"\"";
              nbo = "nix build --offline --builders \"\"";
              nboot = lib.mkIf isNixos "cd ${flakePath}; swarsel-deploy $(hostname) boot; cd -;";
              nd = "nix develop";
              ndry = lib.mkIf isNixos "cd ${flakePath}; swarsel-deploy $(hostname) dry-activate; cd -;";
              nix-ldd = "LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH ldd";
              nix-ldd-locate = "nix-locate --minimal --top-level -w ";
              nix-review-local = "nix run nixpkgs#nixpkgs-review -- rev HEAD";
              nix-review-post = "nix run nixpkgs#nixpkgs-review -- pr --post-result --systems linux";
              nix-store-search = "ls /nix/store | grep";
              ns = "nix shell";
              nswitch = lib.mkIf isNixos "cd ${flakePath}; swarsel-deploy $(hostname) switch; cd -;";
              ntest = lib.mkIf isNixos "cd ${flakePath}; swarsel-deploy $(hostname) test; cd -;";
              passpull = "cd ~/.local/share/password-store; git pull; cd -;";
              passpush = "cd ~/.local/share/password-store; git add .; git commit -m 'pass file changes'; git push; cd -;";
              youtube-dl = "yt-dlp";
            } config.swarselsystems.shellAliases;
            syntaxHighlighting.enable = true;
          };
        };
      };
    nixos.zsh = { pkgs, ... }: {
      config = {
        users.defaultUserShell = pkgs.zsh;
        programs.zsh = {
          enable = true;
          enableCompletion = false;
        };
        environment = {
          pathsToLink = [ "/share/zsh" ];
          shells = with pkgs; [ zsh ];
        };
      };
    };
  };
}
