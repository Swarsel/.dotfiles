{ config, pkgs, lib, minimal, inputs, globals, nixosConfig ? config, ... }:
let
  inherit (config.swarselsystems) flakePath;
  crocDomain = globals.services.croc.domain;
in
{
  options.swarselmodules.zsh = lib.mkEnableOption "zsh settings";
  options.swarselsystems = {
    shellAliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };
  config = lib.mkIf config.swarselmodules.zsh
    ({

      programs.zsh = {
        enable = true;
      }
      // lib.optionalAttrs (!minimal) {
        shellAliases = lib.recursiveUpdate
          {
            hg = "history | grep";
            hmswitch = "home-manager --flake ${flakePath}#$(whoami)@$(hostname) switch |& nom";
            # nswitch = "sudo nixos-rebuild --flake ${flakePath}#$(hostname) --show-trace --log-format internal-json -v switch |& nom --json";
            nswitch = "cd ${flakePath}; swarsel-deploy $(hostname) switch; cd -;";
            nboot = "cd ${flakePath}; swarsel-deploy $(hostname) boot; cd -;";
            ndry = "cd ${flakePath}; swarsel-deploy $(hostname) dry-activate; cd -;";
            # nboot = "sudo nixos-rebuild --flake ${flakePath}#$(hostname) --show-trace --log-format internal-json -v boot |& nom --json";
            magit = "emacsclient -nc -e \"(magit-status)\"";
            config = "git --git-dir=$HOME/.cfg/ --work-tree=$HOME";
            g = "git";
            c = "git --git-dir=$FLAKE/.git --work-tree=$FLAKE/";
            passpush = "cd ~/.local/share/password-store; git add .; git commit -m 'pass file changes'; git push; cd -;";
            passpull = "cd ~/.local/share/password-store; git pull; cd -;";
            hotspot = "nmcli connection up local; nmcli device wifi hotspot;";
            youtube-dl = "yt-dlp";
            cat-orig = "cat";
            cdr = "cd \"$( (find $DOCUMENT_DIR_WORK $DOCUMENT_DIR_PRIV -maxdepth 1 && echo $FLAKE) | fzf )\"";
            nix-ldd-ldd = "LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH ldd";
            nix-ldd = "LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH ldd";
            nix-ldd-locate = "nix-locate --minimal --top-level -w ";
            nix-store-search = "ls /nix/store | grep";
            fs-diff = "sudo mount -o subvol=/ /dev/mapper/cryptroot /mnt ; fs-diff";
            lt = "eza -las modified --total-size";
            boot-diff = "nix store diff-closures /run/*-system";
            gen-diff = "nix profile diff-closures --profile /nix/var/nix/profiles/system";
            cc = "wl-copy";
            build-topology = "nix build .#topology.x86_64-linux.config.output";
            build-iso = "nix build --print-out-paths .#live-iso";
            nix-review- = "nix run nixpkgs#nixpkgs-review -- rev HEAD";
            nix-review-post = "nix run nixpkgs#nixpkgs-review -- pr --post-result --systems linux";
          }
          config.swarselsystems.shellAliases;
        autosuggestion.enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        autocd = false;
        cdpath = [
          "~/.dotfiles"
          # "~/Documents/GitHub"
        ];
        defaultKeymap = "emacs";
        dirHashes = {
          dl = "$HOME/Downloads";
          gh = "$HOME/Documents/GitHub";
        };
        history = {
          expireDuplicatesFirst = true;
          path = "$HOME/.histfile";
          save = 100000;
          size = 100000;
        };
        historySubstringSearch = {
          enable = true;
          searchDownKey = "^[OB";
          searchUpKey = "^[OA";
        };
        plugins = [
          # {
          #   name = "fzf-tab";
          #   src = pkgs.zsh-fzf-tab;
          # }
        ];
        initContent = ''
          my-forward-word() {
            local WORDCHARS=$WORDCHARS
            WORDCHARS="''${WORDCHARS//:}"
            WORDCHARS="''${WORDCHARS//\/}"
            WORDCHARS="''${WORDCHARS//.}"
            zle forward-word
          }
          zle -N my-forward-word
          # ctrl + right
          bindkey "^[[1;5C" my-forward-word

          # shift + right
          bindkey "^[[1;2C" forward-word

          my-backward-word() {
            local WORDCHARS=$WORDCHARS
            WORDCHARS="''${WORDCHARS//:}"
            WORDCHARS="''${WORDCHARS//\/}"
            WORDCHARS="''${WORDCHARS//.}"
            zle backward-word
          }
          zle -N my-backward-word
          # ctrl + left
          bindkey "^[[1;5D" my-backward-word

          # shift + left
          bindkey "^[[1;2D" backward-word

          my-backward-delete-word() {
            local WORDCHARS=$WORDCHARS
            WORDCHARS="''${WORDCHARS//:}"
            WORDCHARS="''${WORDCHARS//\/}"
            WORDCHARS="''${WORDCHARS//.}"
            zle backward-delete-word
          }
          zle -N my-backward-delete-word
          # ctrl + del
          bindkey '^H' my-backward-delete-word
        '';
        sessionVariables = lib.mkIf (!config.swarselsystems.isPublic) {
          CROC_RELAY = crocDomain;
          CROC_PASS = "$(cat ${nixosConfig.sops.secrets.croc-password.path or ""})";
          GITHUB_TOKEN = "$(cat ${nixosConfig.sops.secrets.github-nixpkgs-review-token.path or ""})";
          QT_QPA_PLATFORM_PLUGIN_PATH = "${pkgs.libsForQt5.qt5.qtbase.bin}/lib/qt-${pkgs.libsForQt5.qt5.qtbase.version}/plugins";
          # QTWEBENGINE_CHROMIUM_FLAGS = "--no-sandbox";
        };
      };
    } // lib.optionalAttrs (inputs ? sops) {

      sops.secrets = lib.mkIf (!config.swarselsystems.isPublic && !config.swarselsystems.isNixos) {
        croc-password = { };
        github-nixpkgs-review-token = { };
      };

    });
}
