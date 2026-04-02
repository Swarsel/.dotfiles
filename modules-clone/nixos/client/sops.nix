{ self, config, lib, ... }:
{
  options.swarselmodules.sops = lib.mkEnableOption "sops config";
  config = lib.mkIf config.swarselmodules.sops {
    sops = {

      # age.sshKeyPaths = lib.swarselsystems.mkIfElseList config.swarselsystems.isBtrfs [ "/persist/.ssh/sops" "/persist/.ssh/ssh_host_ed25519_key" ] [ "${config.swarselsystems.homeDir}/.ssh/sops" "/etc/ssh/sops" "/etc/ssh/ssh_host_ed25519_key" ];
      age.sshKeyPaths = [ "${if config.swarselsystems.isImpermanence then "/persist" else ""}/etc/ssh/ssh_host_ed25519_key" ];
      # defaultSopsFile = "${if config.swarselsystems.isImpermanence then "/persist" else ""}${config.swarselsystems.flakePath}/secrets/repo/common.yaml";
      defaultSopsFile = self + "/secrets/repo/common.yaml";

      validateSopsFiles = false;

    };
  };
}
