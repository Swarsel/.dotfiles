{
  flake.modules.homeManager.emacs-init =
    { root, confLib, ... }:
    let
      inherit (confLib.getConfig.repo.secrets.common.names) dashboard;
    in
    {
      config.programs.emacs.init.usePackage.dashboard = {
        config = ''
          (dashboard-setup-startup-hook)

          (let ((files-domain (getenv "SWARSEL_FILES_DOMAIN"))
                (music-domain (getenv "SWARSEL_MUSIC_DOMAIN"))
                (insta-domain (getenv "SWARSEL_INSTA_DOMAIN"))
                (sport-domain (getenv "SWARSEL_SPORT_DOMAIN"))
                (swarsel-domain (getenv "SWARSEL_DOMAIN"))
                )
            (setq dashboard-display-icons-p t
                  dashboard-icon-type 'nerd-icons
                  dashboard-set-file-icons t
                  dashboard-items '((recents . 5)
                                    (projects . 5)
                                    (agenda . 5))
                  dashboard-set-footer nil
                  dashboard-banner-logo-title "${dashboard.title}"
                  dashboard-image-banner-max-height 300
                  dashboard-startup-banner "${root "files/icons/swarsel.png"}"
                  dashboard-projects-backend 'projectile
                  dashboard-projects-switch-function 'magit-status
                  dashboard-set-navigator t
                  dashboard-startupify-list '(dashboard-insert-banner
                                              dashboard-insert-newline
                                              dashboard-insert-banner-title
                                              dashboard-insert-newline
                                              dashboard-insert-navigator
                                              dashboard-insert-newline
                                              dashboard-insert-init-info
                                              dashboard-insert-items
                                              )
                  dashboard-navigator-buttons
                  `(;; line1
                    ((,(char-to-string #xf16d)
                      "${dashboard.social}"
                      "${dashboard.socialHelp}"
                      (lambda (&rest _) (browse-url ,insta-domain)))

                     (,(char-to-string #xf001)
                      "${dashboard.music}"
                      "${dashboard.musicHelp}"
                      (lambda (&rest _) (browse-url ,(concat "https://" music-domain))) )
                     (,(char-to-string #xf09b)
                      "${dashboard.github}"
                      "${dashboard.githubHelp}"
                      (lambda (&rest _) (browse-url "https://github.com/Swarsel")) )
                     (,(char-to-string #xebaa)
                      "${dashboard.files}"
                      "${dashboard.filesHelp}"
                      (lambda (&rest _) (browse-url ,(concat "https://" files-domain))) )
                     (,(char-to-string #xf0ad1)
                      "${dashboard.sport}"
                      "${dashboard.sportHelp}"
                      (lambda (&rest _) (browse-url ,sport-domain)))
                     )
                    (
                     (,(char-to-string #xf1105)
                      ,swarsel-domain
                      ,(concat "Browse " swarsel-domain)
                      (lambda (&rest _) (browse-url ,(concat "https://" swarsel-domain))))
                     )
                    )))
        '';
        enable = true;
      };
    };
}
