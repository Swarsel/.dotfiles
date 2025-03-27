{ self, config, ... }:
{
  services.openssh = {
    enable = true;
  };
  users.users."${config.swarselsystems.mainUser}".openssh.authorizedKeys.keyFiles = [
    (self + /secrets/keys/ssh/yubikey.pub)
    (self + /secrets/keys/ssh/magicant.pub)
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    (self + /secrets/keys/ssh/yubikey.pub)
    (self + /secrets/keys/ssh/magicant.pub)
  ];
  security.sudo.extraConfig = ''
    Defaults    env_keep+=SSH_AUTH_SOCK
  '';

}
