{ config, lib, ... }:
{
  options.swarselsystems.server.sops = lib.mkEnableOption "enable sops on server";
  config = lib.mkIf config.swarselsystems.server.sops {
    sops = {
      age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/sops" ];
      defaultSopsFile = lib.mkDefault "${config.swarselsystems.flakePath}/secrets/winters/secrets.yaml";
      validateSopsFiles = false;
    };
  };
}
