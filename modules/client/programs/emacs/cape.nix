{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.cape = {
    enable = true;
    bind = {
      "C-z p" = "completion-at-point";
      "C-z t" = "complete-tag";
      "C-z d" = "cape-dabbrev";
      "C-z h" = "cape-history";
      "C-z f" = "cape-file";
      "C-z k" = "cape-keyword";
      "C-z s" = "cape-elisp-symbol";
      "C-z e" = "cape-elisp-block";
      "C-z a" = "cape-abbrev";
      "C-z l" = "cape-line";
      "C-z w" = "cape-dict";
      "C-z :" = "cape-emoji";
      "C-z \\\\" = "cape-tex";
      "C-z _" = "cape-tex";
      "C-z ^" = "cape-tex";
      "C-z &" = "cape-sgml";
      "C-z r" = "cape-rfc1345";
    };
  };
}
