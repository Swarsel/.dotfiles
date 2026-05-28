{ self, config, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${self}/profiles/nixos/public"
    "${m}/nixos/client/hardwarecompatibility-yubikey.nix"
    "${m}/nixos/server/ssh.nix"
  ];

  config.home-manager.users."${config.swarselsystems.mainUser}" = {
    imports = [
      "${m}/../profiles/home/personal"
    ];
  };
}
