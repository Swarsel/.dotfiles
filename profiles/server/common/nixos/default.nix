{ self, ... }:
let
  profilesPath = "${self}/profiles";
in
{
  imports = [
    "${profilesPath}/common/nixos/settings.nix"
    "${profilesPath}/common/nixos/home-manager.nix"
    "${profilesPath}/common/nixos/xserver.nix"
    "${profilesPath}/common/nixos/gc.nix"
    "${profilesPath}/common/nixos/store.nix"
    "${profilesPath}/common/nixos/time.nix"
    "${profilesPath}/common/nixos/pipewire.nix"
    "${profilesPath}/common/nixos/users.nix"
    "${profilesPath}/common/nixos/nix-ld.nix"
    ./settings.nix
    ./packages.nix
    ./sops.nix
    ./ssh.nix
    ./nfs.nix
    ./nginx.nix
    ./kavita.nix
    ./jellyfin.nix
    ./navidrome.nix
    ./spotifyd.nix
    ./mpd.nix
    ./matrix.nix
    ./nextcloud.nix
    ./immich.nix
    ./paperless.nix
    ./transmission.nix
    ./syncthing.nix
    ./restic.nix
    ./monitoring.nix
    ./jenkins.nix
    ./emacs.nix
  ];
}
