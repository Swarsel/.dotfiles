{ self, ... }:
{
  services.openssh = {
    enable = true;
  };
  users.users.swarsel.openssh.authorizedKeys.keyFiles = [
    (self + /secrets/keys/ssh/nbl-imba-2.pub)
    (self + /secrets/keys/ssh/magicant.pub)
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    (self + /secrets/keys/ssh/nbl-imba-2.pub)
    (self + /secrets/keys/ssh/magicant.pub)
  ];

}
