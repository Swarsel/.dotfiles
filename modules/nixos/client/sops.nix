{ config, lib, ... }:
{
  options.swarselsystems.modules.sops = lib.mkEnableOption "sops config";
  config = lib.mkIf config.swarselsystems.modules.sops {
    sops = {

      # age.sshKeyPaths = lib.swarselsystems.mkIfElseList config.swarselsystems.isBtrfs [ "/persist/.ssh/sops" "/persist/.ssh/ssh_host_ed25519_key" ] [ "${config.swarselsystems.homeDir}/.ssh/sops" "/etc/ssh/sops" "/etc/ssh/ssh_host_ed25519_key" ];
      age.sshKeyPaths = [ "${config.swarselsystems.homeDir}/.ssh/sops" "/etc/ssh/sops" "/etc/ssh/ssh_host_ed25519_key" ];
      # defaultSopsFile = lib.swarselsystems.mkIfElseList config.swarselsystems.isBtrfs "/persist/.dotfiles/secrets/general/secrets.yaml" "${config.swarselsystems.flakePath}/secrets/general/secrets.yaml";
      defaultSopsFile = "${config.swarselsystems.flakePath}/secrets/general/secrets.yaml";

      validateSopsFiles = false;

    };
  };
}
