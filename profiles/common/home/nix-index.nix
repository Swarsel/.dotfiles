{ pkgs, ... }:
{
  programs.nix-index =
    let
      commandNotFound = pkgs.runCommandLocal "command-not-found.sh" { } ''
        mkdir -p $out/etc/profile.d
        substitute ${../../../scripts/command-not-found.sh}                  \
          $out/etc/profile.d/command-not-found.sh             \
          --replace @nix-locate@ ${pkgs.nix-index}/bin/nix-locate \
          --replace @tput@ ${pkgs.ncurses}/bin/tput
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
