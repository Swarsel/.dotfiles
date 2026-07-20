{
  flake.modules.homeManager.password-store =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "passwordstore" ];
        programs.password-store = {
          enable = true;
          package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
          settings.PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.local/share/password-store";
        };
        home.activation.setupPasswordStore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          set -eu
          storeDir="${config.programs.password-store.settings.PASSWORD_STORE_DIR}"
          if [ ! -e "$storeDir" ]; then
            GIT_SSH_COMMAND='${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new' \
              ${pkgs.git}/bin/git clone git@github.com:Swarsel/secrets.git "$storeDir" || true
          fi
        '';
      };
    };
}
