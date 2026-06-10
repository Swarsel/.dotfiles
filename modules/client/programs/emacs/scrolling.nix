{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init = {
    prelude = ''
      (setq mouse-wheel-scroll-amount
            '(1
              ((shift) . 5)
              ((meta) . 0.5)
              ((control) . text-scale))
            mouse-drag-copy-region nil
            make-pointer-invisible t
            mouse-wheel-follow-mouse t)

      (setq-default scroll-preserve-screen-position t
                    next-screen-context-lines 0)
    '';

    usePackage.ultra-scroll = {
      enable = true;
      init = ''
        (setq scroll-conservatively 101
              scroll-margin 0)
      '';
      custom = {
        ultra-scroll-hide-functions = "'(global-hl-line-mode diff-hl-mode indent-bars-mode global-highlight-parentheses-mode rainbow-delimiters-mode)";
      };
      config = "(ultra-scroll-mode 1)";
    };
  };
}
