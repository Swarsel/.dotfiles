_:
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.swarsel.openssh.authorizedKeys.keyFiles = [
    ../../../secrets/keys/authorized_keys
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../../secrets/keys/authorized_keys
  ];

}
