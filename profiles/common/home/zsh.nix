{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = lib.recursiveUpdate
      {
        hg = "history | grep";
        hmswitch = "cd ~/.dotfiles; home-manager --flake .#$(whoami)@$(hostname) switch; cd -;";
        nswitch = "cd ~/.dotfiles; sudo nixos-rebuild --flake .#$(hostname) switch; cd -;";
        nswitch-stay = "cd ~/.dotfiles; git restore flake.lock; sudo nixos-rebuild --flake .#$(hostname) switch; cd -;";
        edithome = "e -w ~/.dotfiles/SwarselSystems.org";
        magit = "emacsclient -nc -e \"(magit-status)\"";
        config = "git --git-dir=$HOME/.cfg/ --work-tree=$HOME";
        g = "git";
        c = "git --git-dir=$HOME/.dotfiles/.git --work-tree=$HOME/.dotfiles/";
        passpush = "cd ~/.local/share/password-store; git add .; git commit -m 'pass file changes'; git push; cd -;";
        passpull = "cd ~/.local/share/password-store; git pull; cd -;";
        hotspot = "nmcli connection up local; nmcli device wifi hotspot;";
        cd = "z";
        cdr = "cd \"$( (find /home/swarsel/Documents/GitHub -maxdepth 1 && echo /home/swarsel/.dotfiles) | fzf )\"";
        nix-ldd = "LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH ldd";
        fs-diff = "sudo mount -o subvol=/ /dev/mapper/cryptroot /mnt ; fs-diff";
        lt = "ls -lath";
        oldshell = "nix shell github:nixos/nixpkgs/\"$1\" \"$2\"";
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
      save = 10000;
      size = 10000;
    };
    historySubstringSearch.enable = true;
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
      }
    ];
    initExtra = ''
      bindkey "^[[1;5D" backward-word
      bindkey "^[[1;5C" forward-word

      vterm_printf() {
        if [ -n "$TMUX" ] && ([ "''${TERM%%-*}" = "tmux" ] || [ "''${TERM%%-*}" = "screen" ]); then
          # Tell tmux to pass the escape sequences through
          printf "\ePtmux;\e\e]%s\007\e\\" "$1"
        elif [ "''${TERM%%-*}" = "screen" ]; then
          # GNU screen (screen, screen-256color, screen-256color-bce)
          printf "\eP\e]%s\007\e\\" "$1"
        else
          printf "\e]%s\e\\" "$1"
        fi
                 }
    '';
  };
}
