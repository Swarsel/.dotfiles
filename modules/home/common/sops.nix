{ config, lib, ... }:
let
  inherit (config.swarselsystems) homeDir xdgDir;
in
{
  options.swarselsystems.modules.sops = lib.mkEnableOption "sops settings";
  config = lib.mkIf config.swarselsystems.modules.sops {
    sops = {
      age.sshKeyPaths = [ "${homeDir}/.ssh/sops" "${homeDir}/.ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = lib.swarselsystems.mkIfElseList config.swarselsystems.isBtrfs "/persist/.dotfiles/secrets/general/secrets.yaml" "${homeDir}/.dotfiles/secrets/general/secrets.yaml";

      validateSopsFiles = false;
      secrets = lib.mkIf (!config.swarselsystems.isPublic) {
        mrswarsel = { path = "${xdgDir}/secrets/mrswarsel"; };
        nautilus = { path = "${xdgDir}/secrets/nautilus"; };
        leon = { path = "${xdgDir}/secrets/leon"; };
        swarselmail = { path = "${xdgDir}/secrets/swarselmail"; };
        github_notif = { path = "${xdgDir}/secrets/github_notif"; };
        u2f_keys = { path = "${homeDir}/.config/Yubico/u2f_keys"; };
      };
    };
  };
}
