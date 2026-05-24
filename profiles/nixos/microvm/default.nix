{ self, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    # common modules
    "${m}/nixos/common/settings.nix"
    "${m}/nixos/common/pii.nix"
    "${m}/nixos/common/xserver.nix"
    "${m}/nixos/common/time.nix"
    "${m}/nixos/common/users.nix"
    "${m}/nixos/common/impermanence.nix"
    "${m}/nixos/common/sops.nix"
    # server modules
    "${m}/nixos/server/btrfs.nix"
    "${m}/nixos/server/nftables.nix"
    "${m}/nixos/server/settings.nix"
    "${m}/nixos/server/id.nix"
    "${m}/nixos/server/packages.nix"
    "${m}/nixos/server/ssh.nix"
    "${m}/nixos/server/wireguard.nix"
    "${m}/nixos/server/dns-home.nix"
    "${m}/nixos/server/opkssh.nix"
    # "${m}/nixos/server/oauth2-proxy.nix"
    "${m}/nixos/server/node-roles.nix"
    "${m}/nixos/server/alloy.nix"
    "${m}/nixos/server/blackbox.nix"
  ];

  config.swarselsystems = {
    isLinux = true;
    isNixos = true;
  };
}
