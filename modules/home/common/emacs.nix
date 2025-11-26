{ self, lib, config, pkgs, globals, inputs, ... }:
let
  inherit (config.swarselsystems) homeDir mainUser isPublic isNixos;
  inherit (config.repo.secrets.common.emacs) radicaleUser;
in
{
  options.swarselmodules.emacs = lib.mkEnableOption "emacs settings";
  config = lib.mkIf config.swarselmodules.emacs ({
    # needed for elfeed
    # enable emacs overlay for bleeding edge features
    # also read init.el file and install use-package packages

    home.activation.setupEmacsOrgFiles =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu

        if [ ! -d ${homeDir}/Org ]; then
          ${pkgs.coreutils}/bin/install -d -m 0755 ${homeDir}/Org
          ${pkgs.coreutils}/bin/chown ${mainUser}:syncthing ${homeDir}/Org
        fi

        # create dummy files to make Emacs calendar work
        # these have low modified dates and should be marked as sync-conflicts
        for file in "Tasks" "Archive" "Journal"; do
          if [ ! -f ${homeDir}/Org/"$file".org ]; then
            ${pkgs.coreutils}/bin/touch --time=access --time=modify -t 197001010000.00 ${homeDir}/Org/"$file".org
            ${pkgs.coreutils}/bin/chown ${mainUser}:syncthing ${homeDir}/Org/"$file".org
          fi
        done

        # when the configuration is build again, these sync-conflicts will be cleaned up
        for file in $(find ${homeDir}/Org/ -name "*sync-conflict*"); do
          ${pkgs.coreutils}/bin/rm "$file"
        done
      '';

    programs.emacs = {
      enable = true;
      package = pkgs.emacsWithPackagesFromUsePackage {
        config = self + /files/emacs/init.el;
        package = pkgs.emacs-git-pgtk;
        alwaysEnsure = true;
        alwaysTangle = true;
        extraEmacsPackages = epkgs: [
          epkgs.mu4e
          epkgs.use-package
          epkgs.lsp-bridge
          epkgs.doom-themes
          epkgs.vterm
          # pkgs.stable.emacs.pkgs.elpaPackages.tramp # use the unstable version from elpa
          epkgs.treesit-grammars.with-all-grammars

          # build the rest of the packages myself
          # org-calfw is severely outdated on MELPA and throws many warnings on emacs startup
          # build the package from the haji-ali fork, which is well-maintained

          (epkgs.trivialBuild rec {
            pname = "eglot-booster";
            version = "main-29-10-2024";

            src = pkgs.fetchFromGitHub {
              owner = "jdtsmith";
              repo = "eglot-booster";
              rev = "e6daa6bcaf4aceee29c8a5a949b43eb1b89900ed";
              hash = "sha256-PLfaXELkdX5NZcSmR1s/kgmU16ODF8bn56nfTh9g6bs=";
            };

            packageRequires = [ epkgs.jsonrpc epkgs.eglot ];
          })
          (inputs.nixpkgs-dev.legacyPackages.${pkgs.system}.emacsPackagesFor pkgs.emacs-git-pgtk).calfw
          # epkgs.calfw
          # (epkgs.trivialBuild rec {
          #   pname = "calfw";
          #   version = "1.0.0-20231002";
          #   src = pkgs.fetchFromGitHub {
          #     owner = "haji-ali";
          #     repo = "emacs-calfw";
          #     rev = "bc99afee611690f85f0cd0bd33300f3385ddd3d3";
          #     hash = "sha256-0xMII1KJhTBgQ57tXJks0ZFYMXIanrOl9XyqVmu7a7Y=";
          #   };
          #   packageRequires = [ epkgs.howm ];
          # })

          (epkgs.trivialBuild rec {
            pname = "fast-scroll";
            version = "1.0.0-20191016";
            src = pkgs.fetchFromGitHub {
              owner = "ahungry";
              repo = "fast-scroll";
              rev = "3f6ca0d5556fe9795b74714304564f2295dcfa24";
              hash = "sha256-w1wmJW7YwXyjvXJOWdN2+k+QmhXr4IflES/c2bCX3CI=";
            };
            packageRequires = [ ];
          })

        ];
      };
    };

    services.emacs = {
      enable = true;
      socketActivation.enable = false;
      startWithUserSession = "graphical";
    };

  } // lib.optionalAttrs (inputs ? sops) {

    sops = lib.mkIf (!isPublic && !isNixos) {
      secrets = {
        fever-pw = { path = "${homeDir}/.emacs.d/.fever"; };
        emacs-radicale-pw = { };
        github-forge-token = { };
      };
      templates = {
        authinfo = {
          path = "${homeDir}/.emacs.d/.authinfo";
          content = ''
            machine ${globals.services.radicale.domain} login ${radicaleUser} password ${config.sops.placeholder.emacs-radicale-pw}
            machine api.github.com login ${mainUser}^forge password ${config.sops.placeholder.github-forge-token}
          '';
        };
      };
    };

  });
}
