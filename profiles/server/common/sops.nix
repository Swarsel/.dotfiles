{ pkgs, ... }:
{
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/sops" ];
    defaultSopsFile = "/.dotfiles/secrets/server/winters/secrets.yaml";
    validateSopsFiles = false;
  };

}
