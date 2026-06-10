{
  flake.modules.homeManager.emacs-init = { pkgs, inputs, config, ... }:
    let
      calfw = _: (inputs.nixpkgs-dev.legacyPackages.${pkgs.stdenv.hostPlatform.system}.emacsPackagesFor config.programs.emacs.package).calfw;
    in
    {
      config.programs.emacs.init.usePackage = {
        general.config = ''
          (swarsel/leader-keys
            "mc" '((lambda () (interactive) (swarsel/open-calendar)) :which-key "calendar"))
        '';

        org-caldav = {
          enable = true;
          init = ''
            (setq swarsel-caldav-synced 0)
          '';
          config = ''
            (setq org-icalendar-alarm-time 1)
            (setq org-icalendar-include-todo t)
            (setq org-icalendar-use-deadline '(event-if-todo event-if-not-todo todo-due))
            (setq org-icalendar-use-scheduled '(todo-start event-if-todo event-if-not-todo))
          '';
        };

        calfw = {
          enable = true;
          package = calfw;
          bind = {
            "C-c A" = "swarsel/open-calendar";
          };
          init = ''
            (defun swarsel/open-calendar ()
              (interactive)
              (cfw:open-calendar-buffer
               :contents-sources
               (list
                (cfw:org-create-source "Blue")
                (cfw:ical-create-source (getenv "SWARSEL_CAL1NAME") (getenv "SWARSEL_CAL1") "Cyan")
                (cfw:ical-create-source (getenv "SWARSEL_CAL2NAME") (getenv "SWARSEL_CAL2") "Green")
                (cfw:ical-create-source (getenv "SWARSEL_CAL3NAME") (getenv "SWARSEL_CAL3") "Magenta")
                )))

            (require 'calfw-cal)
            (require 'calfw-org)
            (require 'calfw-ical)
          '';
          config = ''
            (bind-key "g" 'cfw:refresh-calendar-buffer cfw:calendar-mode-map)
            (bind-key "q" 'evil-quit cfw:details-mode-map)
            (setq calendar-day-name-array
                  ["Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"])

            (setq calendar-week-start-day 1)
          '';
        };
      };
    };
}
