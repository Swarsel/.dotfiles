{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = lib.recursiveUpdate
      {
        hg = "history | grep";
        hmswitch = "home-manager --flake ${config.swarselsystems.flakePath}#$(whoami)@$(hostname) switch |& nom";
        nswitch = "sudo nixos-rebuild --flake ${config.swarselsystems.flakePath}#$(hostname) --show-trace --log-format internal-json -v switch |& nom --json";
        nboot = "sudo nixos-rebuild --flake ${config.swarselsystems.flakePath}#$(hostname) --show-trace --log-format internal-json -v boot |& nom --json";
        magit = "emacsclient -nc -e \"(magit-status)\"";
        config = "git --git-dir=$HOME/.cfg/ --work-tree=$HOME";
        g = "git";
        c = "git --git-dir=$FLAKE/.git --work-tree=$FLAKE/";
        passpush = "cd ~/.local/share/password-store; git add .; git commit -m 'pass file changes'; git push; cd -;";
        passpull = "cd ~/.local/share/password-store; git pull; cd -;";
        hotspot = "nmcli connection up local; nmcli device wifi hotspot;";
        cd = "z";
        cd-orig = "cd";
        cat-orig = "cat";
        cdr = "cd \"$( (find $DOCUMENT_DIR_WORK $DOCUMENT_DIR_PRIV -maxdepth 1 && echo $FLAKE) | fzf )\"";
        nix-ldd = "LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH ldd";
        fs-diff = "sudo mount -o subvol=/ /dev/mapper/cryptroot /mnt ; fs-diff";
        lt = "eza -las modified --total-size";
        boot-diff = "nix store diff-closures /run/*-system";
        gen-diff = "nix profile diff-closures --profile /nix/var/nix/profiles/system";
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

      my-backward-delete-word() {
          # Copy the global WORDCHARS variable to a local variable. That way any
          # modifications are scoped to this function only
          local WORDCHARS=$WORDCHARS
          # Use bash string manipulation to remove `:` so our delete will stop at it
          WORDCHARS="''${WORDCHARS//:}"
          # Use bash string manipulation to remove `/` so our delete will stop at it
          WORDCHARS="''${WORDCHARS//\/}"
          # Use bash string manipulation to remove `.` so our delete will stop at it
          WORDCHARS="''${WORDCHARS//.}"
          # zle <widget-name> will run an existing widget.
          zle backward-delete-word
      }
      zle -N my-backward-delete-word
      bindkey '^H' my-backward-delete-word

      # This will be our `ctrl+alt+w` command
      my-backward-delete-whole-word() {
          # Copy the global WORDCHARS variable to a local variable. That way any
          # modifications are scoped to this function only
          local WORDCHARS=$WORDCHARS
          # Use bash string manipulation to add `:` to WORDCHARS if it's not present
          # already.
          [[ ! $WORDCHARS == *":"* ]] && WORDCHARS="$WORDCHARS"":"
          # zle <widget-name> will run that widget.
          zle backward-delete-word
      }
      # `zle -N` will create a new widget that we can use on the command line
      zle -N my-backward-delete-whole-word
      # bind this new widget to `ctrl+alt+w`
      bindkey '^W' my-backward-delete-whole-word

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
      vterm_prompt_end() {
            vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
      }
      setopt PROMPT_SUBST
      PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'

      vterm_cmd() {
          local vterm_elisp
          vterm_elisp=""
          while [ $# -gt 0 ]; do
              vterm_elisp="$vterm_elisp""$(printf '"%s" ' "$(printf "%s" "$1" | sed -e 's|\\|\\\\|g' -e 's|"|\\"|g')")"
              shift
          done
          vterm_printf "51;E$vterm_elisp"
      }

    '';
  };
}
