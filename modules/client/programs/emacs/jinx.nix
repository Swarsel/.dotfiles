{
  flake.modules.homeManager.emacs-init = { pkgs, ... }: {
    config = {
      programs.emacs.init.usePackage.jinx = {
        enable = true;
        bind = {
          "C-M-$" = "jinx-languages";
          "M-$" = "jinx-correct";
        };
        custom.jinx-languages = ''"en_US"'';
        hook = [
          "(text-mode . jinx-mode)"
          "(prog-mode . jinx-mode)"
          "(conf-mode . jinx-mode)"
        ];
      };
      home.packages = [
        pkgs.enchant
        pkgs.hunspellDicts.en_US
      ];
    };
  };
}
