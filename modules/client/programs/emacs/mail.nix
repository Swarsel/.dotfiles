{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    general.config = ''
      (swarsel/leader-keys
        "mm" '((lambda () (interactive) (mu4e)) :which-key "mu4e"))
    '';

    mu4e = {
      config = ''
        (advice-add 'mu4e--server-filter :around #'suppress-messages)

        (setq send-mail-function 'sendmail-send-it)
        (setq mu4e-change-filenames-when-moving t)
        (setq mu4e-mu-binary (executable-find "mu"))
        (setq mu4e-hide-index-messages t)

        (setq mu4e-search-skip-duplicates nil)

        (setq mu4e-update-interval 60)
        (setq mu4e-get-mail-command "mbsync -a")
        (setq mu4e-maildir "~/Mail")

        (setq mu4e-view-show-images t)
        (when (fboundp 'imagemagick-register-types)
          (imagemagick-register-types))

        (setq mu4e-drafts-folder "/Drafts")
        (setq mu4e-sent-folder   "/Sent Mail")
        (setq mu4e-refile-folder "/All Mail")
        (setq mu4e-trash-folder  "/Trash")

        (setq mu4e-maildir-shortcuts
              '((:maildir "/leon/Inbox"    :key ?1)
                (:maildir "/nautilus/Inbox" :key ?2)
                (:maildir "/mrswarsel/Inbox"     :key ?3)
                (:maildir "/work/Inbox"     :key ?4)
                (:maildir "/Sent Mail"     :key ?s)
                (:maildir "/Trash"     :key ?t)
                (:maildir "/Drafts"     :key ?d)
                (:maildir "/All Mail"     :key ?a)))

        (setq user-mail-address (getenv "SWARSEL_MAIL4")
              user-full-name (getenv "SWARSEL_FULLNAME"))

        (setq mu4e-user-mail-address-list
              (mapcar #'intern (split-string (or (getenv "SWARSEL_MAIL_ALL") "") "[ ,]+" t)))

        (setq mu4e--log-max-size 1000)

        (mu4e t)

        (let ((work (getenv "SWARSEL_MAIL_WORK")))
          (when (and work (not (string-empty-p work)))
            (setq swarsel-smime-cert-path "~/.Certificates/$SWARSEL_MAIL_WORK.pem")
            (setq swarsel-smime-cert-path (substitute-env-vars swarsel-smime-cert-path))
            (setq mml-secure-prefer-scheme 'smime)
            (setq mml-secure-smime-sign-with-sender t)
            (add-hook 'mu4e-compose-mode-hook
                      (lambda ()
                        (when (and (boundp 'user-mail-address)
                                   (stringp user-mail-address)
                                   (string-equal user-mail-address (getenv "SWARSEL_MAIL_WORK")))
                          (mml-secure-message-sign-smime))))
            (setq smime-keys
                  `((,(getenv "SWARSEL_MAIL_WORK")
                     ,swarsel-smime-cert-path
                     ("~/Certificates/harica-root.pem"
                      "~/Certificates/harica-intermediate.pem"))))
            ))

        (setq mu4e-bookmarks
              `((:name "Unread messages" :query "flag:unread AND NOT flag:trashed" :key 117)
                (:name "Undeleted messages" :query "NOT flag:trashed" :key 103)
                (:name "Today's messages" :query "date:today..now" :key 116)
                (:name "Today's undeleted messages" :query "date:today..now AND NOT flag:trashed" :key 100)
                (:name "Last 7 days" :query "date:7d..now" :hide-unread t :key 119)
                (:name "Messages with images" :query "mime:image/*" :key 112))
              )
      '';
      enable = true;
      package = "mu4e";
      hook = [
        "(mu4e-compose-mode . swarsel/mu4e-send-from-correct-address)"
        "(mu4e-compose-post . swarsel/mu4e-restore-default)"
      ];
      init = ''
        (defun swarsel/mu4e-switch-account ()
          (interactive)
          (let ((account (completing-read "Select account: " mu4e-user-mail-address-list)))
            (setq user-mail-address account)))

        (defun swarsel/mu4e-rfs--matching-address ()
          (cl-loop for to-data in (mu4e-message-field mu4e-compose-parent-message :to)
                   for to-email = (pcase to-data
                                    (`(_ . email) email)
                                    (x (mu4e-contact-email x)))
                   for to-name =  (pcase to-data
                                    (`(_ . name) name)
                                    (x (mu4e-contact-name x)))
                   when (mu4e-user-mail-address-p to-email)
                   return (list to-name to-email)))

        (defun swarsel/mu4e-send-from-correct-address ()
          (when mu4e-compose-parent-message
            (save-excursion
              (when-let ((dest (swarsel/mu4e-rfs--matching-address)))
                (cl-destructuring-bind (from-user from-addr) dest
                  (setq user-mail-address from-addr)
                  (when (and (boundp 'user-mail-address)
                             (stringp user-mail-address)
                             (string-equal user-mail-address (getenv "SWARSEL_MAIL_WORK")))
                    (mml-secure-message-sign-smime))
                  (message-position-on-field "From")
                  (message-beginning-of-line)
                  (delete-region (point) (line-end-position))
                  (insert (format "%s <%s>" (or from-user user-full-name) from-addr)))))))

        (defun swarsel/mu4e-restore-default ()
          (setq user-mail-address (getenv "SWARSEL_MAIL4")
                user-full-name (getenv "SWARSEL_FULLNAME")))
      '';
    };

    mu4e-alert = {
      config = ''
        (mu4e-alert-enable-notifications)
        (mu4e-alert-set-default-style 'libnotify)
        (setq mu4e-alert-interesting-mail-query
              (concat "(maildir:/leon/Inbox AND date:today..now"
                      " OR maildir:/work/Inbox AND date:today..now)"
                      " AND flag:unread"))
        (alert-add-rule
         :category "mu4e-alert"
         :predicate (lambda (_) (string-match-p "^mu4e-" (symbol-name major-mode)))
         :continue t)

        (add-hook 'after-init-hook #'mu4e-alert-enable-notifications)
      '';
      enable = true;
    };
  };
}
