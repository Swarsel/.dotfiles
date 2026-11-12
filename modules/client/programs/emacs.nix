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
      inherit (config.swarselsystems) homeDir;
      inherit (confLib.getConfig.repo.secrets.common.emacs) radicaleUser;
      clientsSecrets = confLib.static.sharedSecrets.clients;
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
            emacs-radicale-pw.rekey.keyPrefix = clientsSecrets;
            fever-pw = {
              path = "${homeDir}/.emacs.d/.fever";
              rekey.keyPrefix = clientsSecrets;
            };
            github-forge-token.rekey.keyPrefix = clientsSecrets;
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
          activation.setupEmacsOrgFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ ! -d ${homeDir}/Org ]; then
              install -d -m 0755 -g syncthing ${homeDir}/Org
            fi

            # the old mtime lets syncthing keep the synced copy and rename this one to a sync-conflict
            for file in Tasks Archive Journal; do
              if [ ! -f ${homeDir}/Org/$file.org ]; then
                touch -t 197001010000.00 ${homeDir}/Org/$file.org
                chgrp syncthing ${homeDir}/Org/$file.org
              fi
              find ${homeDir}/Org -maxdepth 1 -empty -name "$file.sync-conflict-*.org" -delete
            done
          '';
          file = {
            ".emacs.d/early-init.el".text = lib.mkBefore ";;; early-init.el --- -*- lexical-binding: t; -*-\n";
            ".emacs.d/init.el".text = lib.mkBefore ";;; init.el --- -*- lexical-binding: t; -*-\n";
          };
        };
      };
    };
}
