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

            (defun swarsel/magit-insert-remote-branch-headers ()
              (when-let* ((branch (magit-get-current-branch)))
                (let ((shown (list (magit-get-upstream-branch branch) (magit-get-push-branch branch))))
                  (dolist (remote (magit-list-remotes))
                    (let ((target (concat remote "/" branch)))
                      (when (and (not (member target shown)) (magit-rev-verify target))
                        (pcase-let ((`(,ahead ,behind) (magit-rev-diff-count branch target)))
                          (magit-insert-section (branch target)
                            (insert (format "%-10s" (concat (capitalize remote) ": "))
                                    (propertize target 'font-lock-face 'magit-branch-remote)
                                    (format " ↑%d ↓%d " ahead behind)
                                    (magit-log--wash-summary (or (magit-rev-format "%s" target) "(no commit message)"))
                                    ?\n)))))))))

            (magit-add-section-hook 'magit-status-headers-hook #'swarsel/magit-insert-remote-branch-headers #'magit-insert-push-branch-header t)

            (transient-define-suffix swarsel/magit-push-current-to-forge (args)
              :if (lambda () (when-let* ((remote (magit-get "forge.remote"))) (magit-remote-p remote)))
              :description (lambda ()
                             (let ((target (concat (magit-get "forge.remote") "/" (magit-get-current-branch))))
                               (concat (propertize target 'face 'magit-branch-remote)
                                       (unless (magit-rev-verify target) ", creating it"))))
              (interactive (list (magit-push-arguments)))
              (let ((branch (magit-get-current-branch)))
                (magit-git-push branch (concat (magit-get "forge.remote") "/" branch) args)))

            (transient-insert-suffix 'magit-push "e" '("f" swarsel/magit-push-current-to-forge))
          '';
          enable = true;
          custom.magit-display-buffer-function = "#'magit-display-buffer-same-window-except-diff-v1";
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
        };
      };
    };
}
