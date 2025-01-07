{ self, pkgs, ... }:
{
  programs.nix-index =
    let
      commandNotFound = pkgs.runCommandLocal "command-not-found.sh" { } ''
        mkdir -p $out/etc/profile.d
        substitute ${self + /scripts/command-not-found.sh}        \
          $out/etc/profile.d/command-not-found.sh                 \
          --replace-fail @nix-locate@ ${pkgs.nix-index}/bin/nix-locate \
          --replace-fail @tput@ ${pkgs.ncurses}/bin/tput
      '';
    in

    {
      enable = true;
      package = pkgs.symlinkJoin {
        name = "nix-index";
        paths = [ commandNotFound ];
      };
    };
}
