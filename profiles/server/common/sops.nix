{ pkgs, ... }:
{
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/sops" ];
    defaultSopsFile = "/.dotfiles/secrets/server/secrets.yaml";
    validateSopsFiles = false;
  };

}
