{
  flake-file.inputs.nur-expressions = {
    flake = false;
    url = "gitlab:rycee/nur-expressions";
  };

  flake.modules.homeManager.emacs =
    {
      self,
      inputs,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) homeDir mainUser;
      inherit (confLib.getConfig.repo.secrets.common.emacs) radicaleUser;
    in
    {
      imports = [
        "${inputs.nur-expressions}/hm-modules/emacs-init.nix"
        self.modules.homeManager.emacs-init
      ];
      config = {
        swarselsystems = {
          enabledHomeModules = [ "emacs" ];

          homeSopsSecrets = {
            emacs-radicale-pw = { };
            fever-pw = {
              path = "${homeDir}/.emacs.d/.fever";
            };
            github-forge-token = { };
          };

          homeSopsTemplates.authinfo = {
            content = ''
              machine ${globals.services.radicale.domain} login ${radicaleUser} password ${confLib.getConfig.sops.placeholder.emacs-radicale-pw}
            '';
            path = "${homeDir}/.emacs.d/.authinfo";
          };
        };
        services.emacs = {
          enable = true;
          socketActivation.enable = false;
          startWithUserSession = "graphical";
        };
        programs.emacs = {
          enable = true;
          package = pkgs.emacs-igc-pgtk;
        };
        home = {
          activation = {
            copyEmacsGeneratedRef = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              ref="${homeDir}/.dotfiles/files/emacs"
              if [ -d "$ref" ]; then
                paths=$(${config.programs.emacs.finalPackage}/bin/emacs -Q --batch --eval \
                  '(progn (require (quote find-func)) (princ (concat (find-library-name "hm-early-init") "\n" (find-library-name "hm-init"))))' 2>/dev/null || true)
                early_src=$(printf '%s\n' "$paths" | ${pkgs.coreutils}/bin/head -n1)
                init_src=$(printf '%s\n' "$paths" | ${pkgs.coreutils}/bin/tail -n1)
                [ -n "$early_src" ] && [ -f "$early_src" ] && ${pkgs.coreutils}/bin/install -m 0644 "$early_src" "$ref/early-init.el"
                [ -n "$init_src" ] && [ -f "$init_src" ] && ${pkgs.coreutils}/bin/install -m 0644 "$init_src" "$ref/init.el"
              fi
            '';
            setupEmacsOrgFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
          };
          file = {
            ".emacs.d/early-init.el".text = lib.mkBefore ";;; early-init.el --- -*- lexical-binding: t; -*-\n";
            ".emacs.d/init.el".text = lib.mkBefore ";;; init.el --- -*- lexical-binding: t; -*-\n";
          };
        };

      };
    };
}
