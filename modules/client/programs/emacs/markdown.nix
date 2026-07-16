{
  flake.modules.homeManager.emacs-init = { lib, ... }: {
    config.programs.emacs.init.usePackage.markdown-mode = {
      enable = true;
      bindLocal.markdown-mode-map = {
        "C-c C-e" = "markdown-do";
        "C-c C-x C-l" = "org-latex-preview";
        "C-c C-x C-u" = "markdown-toggle-url-hiding";
      };
      hook = [ "(markdown-mode . swarsel/markdown-mode-keys)" ];
      init = ''
        (defun swarsel/markdown-mode-keys ()
          "Local markdown key customizations."
          (local-set-key (kbd "C-c C-x C-l") #'org-latex-preview)
          (local-set-key (kbd "C-c C-x C-u") #'markdown-toggle-url-hiding))

        (setq markdown-command "multimarkdown")
      '';
      mode = lib.mkForce [ ''("README\\.md\\'" . gfm-mode)'' ];
    };
  };
}
