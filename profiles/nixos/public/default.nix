{ self, config, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${self}/profiles/nixos/public-small"
    "${m}/nixos/client/appimage.nix"
    "${m}/nixos/client/distrobox.nix"
    "${m}/nixos/client/hardwarecompatibility-keyboards.nix"
    "${m}/nixos/client/hardwarecompatibility-ledger.nix"
    "${m}/nixos/client/lid.nix"
    "${m}/nixos/client/networkdevices.nix"
    "${m}/nixos/client/nix-ld.nix"
  ];

  config.home-manager.users."${config.swarselsystems.mainUser}" = {
    imports = [
      "${m}/../profiles/home/public"
    ];
  };
}
