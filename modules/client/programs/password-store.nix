{
  flake.modules.homeManager.password-store =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "passwordstore" ];
        programs.password-store = {
          enable = true;
          settings = {
            PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
          };
          package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
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
