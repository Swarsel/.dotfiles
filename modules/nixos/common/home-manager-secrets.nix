{ self, lib, config, globals, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
  inherit (config.repo.secrets.common.emacs) radicaleUser;

  certsSopsFile = self + /secrets/repo/certs.yaml;
  workSopsFile = self + /secrets/work/secrets.yaml;
in
{
  config.sops =
    let
      hm = builtins.elem;
      modules = lib.optionals (config.home-manager.users ? "${mainUser}") config.home-manager.users.${mainUser}.swarselsystems.enabledHomeModules;
    in
    {
      secrets = (lib.optionalAttrs (hm "mail" modules) {
        address1-token = { owner = mainUser; };
        address2-token = { owner = mainUser; };
        address3-token = { owner = mainUser; };
        address4-token = { owner = mainUser; };
      }) // (lib.optionalAttrs (hm "waybar" modules) {
        github-notifications-token = { owner = mainUser; };
      }) // (lib.optionalAttrs (hm "emacs" modules) {
        fever-pw = { path = "${homeDir}/.emacs.d/.fever"; owner = mainUser; };
      }) // (lib.optionalAttrs (hm "zsh" modules) {
        croc-password = { owner = mainUser; };
        github-nixpkgs-review-token = { owner = mainUser; };
      }) // (lib.optionalAttrs (hm "emacs" modules) {
        emacs-radicale-pw = { owner = mainUser; };
        github-forge-token = { owner = mainUser; };
      }) // (lib.optionalAttrs (hm "optional-work" modules) {
        harica-root-ca = { sopsFile = certsSopsFile; path = "${homeDir}/.aws/certs/harica-root.pem"; owner = mainUser; };
        yubikey-1 = { sopsFile = workSopsFile; owner = mainUser; };
        yubikey-2 = { sopsFile = workSopsFile; owner = mainUser; };
        yubikey-3 = { sopsFile = workSopsFile; owner = mainUser; };
        ucKey = { sopsFile = workSopsFile; owner = mainUser; };
      }) // (lib.optionalAttrs (hm "optional-noctalia" modules) {
        radicale-token = { owner = mainUser; };
      }) // (lib.optionalAttrs (hm "anki" modules) {
        anki-user = { owner = mainUser; };
        anki-pw = { owner = mainUser; };
      });
      templates = {
        authinfo = lib.mkIf (hm "emacs" modules) {
          path = "${homeDir}/.emacs.d/.authinfo";
          content = ''
            machine ${globals.services.radicale.domain} login ${radicaleUser} password ${config.sops.placeholder.emacs-radicale-pw}
          '';
          owner = mainUser;
        };
      };
    };
}
