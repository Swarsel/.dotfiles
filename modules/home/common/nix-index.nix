{ self, lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.nix-index = lib.mkEnableOption "nix-index settings";
  config = lib.mkIf config.swarselsystems.modules.nix-index {
    programs.nix-index =
      let
        commandNotFound = pkgs.runCommandLocal "command-not-found.sh" { } ''
          mkdir -p $out/etc/profile.d
          substitute ${self + /files/scripts/command-not-found.sh}        \
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
  };
}
