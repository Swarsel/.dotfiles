{
  flake.modules.homeManager.emacs-init = { pkgs, ... }: {
    config = {
      home.packages = [
        pkgs.enchant
        pkgs.hunspellDicts.en_US
      ];

      programs.emacs.init.usePackage.jinx = {
        enable = true;
        hook = [
          "(text-mode . jinx-mode)"
          "(prog-mode . jinx-mode)"
          "(conf-mode . jinx-mode)"
        ];
        custom = {
          jinx-languages = ''"en_US"'';
        };
        bind = {
          "M-$" = "jinx-correct";
          "C-M-$" = "jinx-languages";
        };
      };
    };
  };
}
