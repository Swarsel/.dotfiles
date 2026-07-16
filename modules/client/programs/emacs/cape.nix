{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.cape = {
    enable = true;
    bind = {
      "C-z &" = "cape-sgml";
      "C-z :" = "cape-emoji";
      "C-z \\\\" = "cape-tex";
      "C-z ^" = "cape-tex";
      "C-z _" = "cape-tex";
      "C-z a" = "cape-abbrev";
      "C-z d" = "cape-dabbrev";
      "C-z e" = "cape-elisp-block";
      "C-z f" = "cape-file";
      "C-z h" = "cape-history";
      "C-z k" = "cape-keyword";
      "C-z l" = "cape-line";
      "C-z p" = "completion-at-point";
      "C-z r" = "cape-rfc1345";
      "C-z s" = "cape-elisp-symbol";
      "C-z t" = "complete-tag";
      "C-z w" = "cape-dict";
    };
  };
}
