{ config, lib, ... }:
{
  sops = {
    age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/sops" ];
    defaultSopsFile = lib.mkDefault "${config.swarselsystems.flakePath}/secrets/winters/secrets.yaml";
    validateSopsFiles = false;
  };

}
