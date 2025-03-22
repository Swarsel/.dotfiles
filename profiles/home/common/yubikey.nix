{ lib, nix-secrets, ... }:
let
  secretsDirectory = builtins.toString nix-secrets;
  yubikey1 = lib.swarselsystems.getSecret "${secretsDirectory}/yubikey/yubikey1";
  yubikey2 = lib.swarselsystems.getSecret "${secretsDirectory}/yubikey/yubikey2";
in
{
  pam.yubico.authorizedYubiKeys = {
    ids = [
      "${yubikey1}"
      "${yubikey2}"
    ];
  };
}
