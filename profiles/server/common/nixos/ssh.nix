{ self, ... }:
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.swarsel.openssh.authorizedKeys.keyFiles = [
    self + /secrets/keys/authorized_keys
    self + /secrets/keys/magicant.pub
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    self + /secrets/keys/authorized_keys
    self + /secrets/keys/magicant.pub
  ];

}
