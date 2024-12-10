{ self, inputs, config, pkgs, lib, modulesPath, ... }:
let
  pubKeys = lib.filesystem.listFilesRecursive "${self}/secrets/keys/ssh";
in
{

  imports = [

    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"

    "${self}/profiles/iso//minimal.nix"

  ];


  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    squashfsCompression = "zstd -Xcompression-level 3";
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  services.getty.autologinUser = lib.mkForce "swarsel";

  users = {
    groups.swarsel = { };
    users = {
      swarsel = {
        name = "swarsel";
        group = "swarsel";
        isNormalUser = true;
        shell = pkgs.zsh;
        password = "setup"; # this is overwritten after install
        openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);
      };
      root = {
        shell = pkgs.zsh;
        password = lib.mkForce config.users.users.swarsel.password; # this is overwritten after install
        openssh.authorizedKeys.keys = config.users.users.swarsel.openssh.authorizedKeys.keys;
      };
    };
  };

  systemd = {
    services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };

  system.stateVersion = lib.mkForce "23.05";

  networking = {
    hostName = "live";
    wireless.enable = false;
  };

}
