{ self, pkgs, inputs, outputs, config, lib, modulesPath, ... }:
let
  pubKeys = lib.filesystem.listFilesRecursive "${self}/secrets/keys/ssh";
in
{

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"

    "${self}/profiles/iso/minimal.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = [
        "${self}/profiles/home/common/settings.nix"
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ];

  home-manager.users.swarsel.home = {
    file = {
      ".bash_history" = {
        source = self + /programs/bash/.bash_history;
      };
    };
  };
  home-manager.users.root.home = {
    stateVersion = "23.05";
    file = {
      ".bash_history" = {
        source = self + /programs/bash/.bash_history;
      };
    };
  };

  # environment.etc."issue".text = "\x1B[32m~SwarselSystems~\x1B[0m\nIP of primary interface: \x1B[31m\\4\x1B[0m\nThe Password for all users & root is '\x1B[31msetup\x1B[0m'.\nInstall the system remotely by running '\x1B[33mbootstrap -n <HOSTNAME> -d <IP_FROM_ABOVE> [--impermanence] [--encryption]\x1B[0m' on a machine with deployed secrets.\nAlternatively, run '\x1B[33mswarsel-install -d <DISK> -f <flake>\x1B[0m' for a local install.\n";
  environment.etc."issue".source = "${self}/programs/etc/issue";
  networking.dhcpcd.runHook = "${pkgs.utillinux}/bin/agetty --reload";

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
    allowNoPasswordLogin = true;
    groups.swarsel = { };
    users = {
      swarsel = {
        name = "swarsel";
        group = "swarsel";
        isNormalUser = true;
        password = "setup"; # this is overwritten after install
        openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);
        extraGroups = [ "wheel" ];
      };
      root = {
        # password = lib.mkForce config.users.users.swarsel.password; # this is overwritten after install
        openssh.authorizedKeys.keys = config.users.users.swarsel.openssh.authorizedKeys.keys;
      };
    };
  };

  boot = {
    loader.systemd-boot.enable = lib.mkForce true;
    loader.efi.canTouchEfiVariables = true;
  };

  programs.bash.shellAliases = {
    "swarsel-install" = "nix run github:Swarsel/.dotfiles#swarsel-install --";
  };

  system.activationScripts.cache = {
    text = ''
      mkdir -p -m=0777 /home/swarsel/.local/state/nix/profiles
      mkdir -p -m=0777 /home/swarsel/.local/state/home-manager/gcroots
      mkdir -p -m=0777 /home/swarsel/.local/share/nix/
      printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' | tee /home/swarsel/.local/share/nix/trusted-settings.json > /dev/null
      mkdir -p /root/.local/share/nix/
      printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' | tee /root/.local/share/nix/trusted-settings.json > /dev/null
    '';
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
    hostName = "drugstore";
    wireless.enable = false;
  };

}
