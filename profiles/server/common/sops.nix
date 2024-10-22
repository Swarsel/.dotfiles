{ config, ... }:
{
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/sops" ];
    defaultSopsFile = "${config.swarselsystems.flakePath}/secrets/server/winters/secrets.yaml";
    validateSopsFiles = false;
  };

}
