{ self, config, lib, type, ... }:
let
  inherit (config.swarselsystems) homeDir;
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "sops" ];
  } // (lib.optionalAttrs (type != "nixos") {
    sops = lib.mkIf (!config.swarselsystems.isNixos) {
      age.sshKeyPaths = [ "${if config.swarselsystems.isImpermanence then "/persist" else ""}${homeDir}/.ssh/sops" ];
      defaultSopsFile = self + "/secrets/repo/common.yaml";

      validateSopsFiles = false;
    };
  });
}
