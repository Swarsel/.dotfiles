{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      hg = "history | grep";
      hmswitch = "cd ~/.dotfiles; home-manager --flake .#$(whoami)@$(hostname) switch; cd -;";
      nswitch = "cd ~/.dotfiles; sudo nixos-rebuild --flake .#$(hostname) switch; cd -;";
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
    };
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
    '';
  };
}
