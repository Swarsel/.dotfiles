{ lib, config, inputs, ... }:
{
  imports = [
    ../../common/nixos/xserver.nix
    ../../common/nixos/gc.nix
    ../../common/nixos/store.nix
    ../../common/nixos/time.nix
    ../../common/nixos/pipewire.nix
    ../../common/nixos/users.nix
    ../../common/nixos/nix-ld.nix
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
  ];

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "ca-derivations"
        ];
        trusted-users = [ "swarsel" ];
        flake-registry = "";
        warn-dirty = false;
      };
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  environment.shellAliases = lib.recursiveUpdate
    {
      npswitch = "cd ${config.swarselsystems.flakePath}; git pull; sudo nixos-rebuild --flake .#$(hostname) switch --impure; cd -;";
      nswitch = "cd ${config.swarselsystems.flakePath}; sudo nixos-rebuild --flake .#$(hostname) switch --impure; cd -;";
    }
    config.swarselsystems.shellAliases;

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  system.stateVersion = lib.mkDefault "23.05";
}
