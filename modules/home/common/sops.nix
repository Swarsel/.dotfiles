{ self, config, lib, type, ... }:
let
  inherit (config.swarselsystems) homeDir;
in
{
  options.swarselmodules.sops = lib.mkEnableOption "sops settings";
  config = lib.optionalAttrs (type != "nixos") {
    sops = lib.mkIf (!config.swarselsystems.isNixos) {
      age.sshKeyPaths = [ "${if config.swarselsystems.isImpermanence then "/persist" else ""}${homeDir}/.ssh/sops" ];
      # defaultSopsFile = "${if config.swarselsystems.isImpermanence then "/persist" else ""}${homeDir}/.dotfiles/secrets/repo/common.yaml";
      defaultSopsFile = self + "/secrets/repo/common.yaml";

      validateSopsFiles = false;
    };
  };
}
