{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.prelude = ''
    (setq message-log-max 30)
    (setq comint-buffer-maximum-size 50)
    (add-hook 'comint-output-filter-functions 'comint-truncate-buffer)
  '';
}
