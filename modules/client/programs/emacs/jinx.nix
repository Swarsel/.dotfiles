{
  flake.modules.homeManager.emacs-init =
    { lib, pkgs, ... }:
    let
      dictionaries = with pkgs.hunspellDicts; [
        de_AT
        de_CH
        de_DE
        en_GB-large
        en_US-large
      ];
    in
    {
      config = {
        programs.emacs.init.usePackage = {
          ispell = {
            enable = true;
            custom.ispell-program-name = ''"${lib.getExe (pkgs.hunspell.withDicts (_: dictionaries))}"'';
          };
          jinx = {
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
        };
        home.packages = dictionaries;
        systemd.user.sessionVariables.DICPATH = lib.makeSearchPath "share/hunspell" dictionaries;
      };
    };
}
