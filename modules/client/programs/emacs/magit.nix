{
  flake.modules.homeManager.emacs-init =
    { config, lib, ... }:
    {
      config.programs.emacs.init.usePackage = {
        general.config = ''
          (swarsel/leader-keys
            "mg" '((lambda () (interactive) (magit-list-repositories)) :which-key "magit-list-repos")
            "lr" '(swarsel/consult-magit-repos :which-key "List repos")
            "lg" '((lambda () (interactive) (magit-list-repositories)) :which-key "list git repos"))

          (general-define-key
           "M-r" 'swarsel/consult-magit-repos)
        '';

        magit = {
          enable = true;
          init = ''
            (declare-function consult--read "consult")

            (defun swarsel/consult-magit-repos ()
              (interactive)
              (require 'magit)
              (let ((repos (magit-list-repos)))
                (unless repos
                  (user-error "No repositories found in `magit-repository-directories'"))
                (let ((repo
                       (if (or (fboundp 'consult--read)
                               (require 'consult nil t))
                           (consult--read repos
                                          :prompt "Magit repo: "
                                          :require-match t
                                          :history 'my/consult-magit-repos-history
                                          :sort t)
                         (completing-read "Magit repo: "
                                          repos
                                          nil
                                          t
                                          nil
                                          'my/consult-magit-repos-history))))
                  (when (and repo (> (length repo) 0))
                    (magit-status repo)))))
          '';
          config = ''
            (advice-add 'magit-auto-revert-mode--init-kludge :around #'suppress-messages)

            (setq magit-repository-directories `((,swarsel-work-projects-directory  . 3)
                                                ${lib.optionalString (builtins.elem "optional-work" config.swarselsystems.enabledHomeModules) "(,swarsel-private-projects-directory . 3)"}
                                                ("~/.dotfiles/" . 0)))
            ;; RET on a hunk/file always opens the editable worktree file at point,
            ;; never a read-only staged blob.
            (with-eval-after-load 'magit-diff
              (define-key magit-hunk-section-map [remap magit-visit-thing] #'magit-diff-visit-worktree-file)
              (define-key magit-file-section-map [remap magit-visit-thing] #'magit-diff-visit-worktree-file))
          '';
          custom = {
            magit-display-buffer-function = "#'magit-display-buffer-same-window-except-diff-v1";
          };
        };
      };
    };
}
