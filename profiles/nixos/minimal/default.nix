{ self, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    # common modules
    "${m}/nixos/common/settings.nix"
    "${m}/nixos/common/home-manager.nix"
    "${m}/nixos/common/xserver.nix"
    "${m}/nixos/common/lanzaboote.nix"
    "${m}/nixos/common/time.nix"
    "${m}/nixos/common/users.nix"
    "${m}/nixos/common/impermanence.nix"
    "${m}/nixos/common/sops.nix"
    "${m}/nixos/common/pii.nix"
    "${m}/nixos/common/boot.nix"
    # client modules
    # "${m}/nixos/client/polkit.nix"
    "${m}/nixos/client/autologin.nix"
    # server modules
    "${m}/nixos/server/btrfs.nix"
    "${m}/nixos/server/ssh.nix"
    "${m}/nixos/server/disk-encrypt.nix"
  ];
}
