{ config, lib, ... }:
let
  inherit (config.swarselsystems) homeDir;
in
{
  options.swarselmodules.sops = lib.mkEnableOption "sops settings";
  config = lib.mkIf config.swarselmodules.sops {
    sops = {
      age.sshKeyPaths = [ "${homeDir}/.ssh/sops" "${homeDir}/.ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = "${homeDir}/.dotfiles/secrets/general/secrets.yaml";

      validateSopsFiles = false;
    };
  };
}
