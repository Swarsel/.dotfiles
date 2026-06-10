{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    rainbow-delimiters = {
      enable = true;
      hook = [ "(prog-mode . rainbow-delimiters-mode)" ];
    };

    highlight-parentheses = {
      enable = true;
      config = ''
        (setq highlight-parentheses-colors '("black" "white" "black" "black" "black" "black" "black"))
        (setq highlight-parentheses-background-colors '("magenta" "blue" "cyan" "green" "yellow" "orange" "red"))
        (global-highlight-parentheses-mode t)
      '';
    };
  };
}
