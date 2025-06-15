{ self, pkgs, inputs, config, lib, modulesPath, primaryUser ? "swarsel", ... }:
let
  pubKeys = lib.filesystem.listFilesRecursive "${self}/secrets/keys/ssh";
in
{

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"

    "${self}/modules/iso/minimal.nix"
    "${self}/modules/nixos/common/sharedsetup.nix"
    "${self}/modules/nixos/common/topology.nix"
    "${self}/modules/home/common/sharedsetup.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users."${primaryUser}".imports = [
        "${self}/modules/home/common/settings.nix"
        "${self}/modules/home/common/sharedsetup.nix"
      ];
    }
  ];

  options.node = {
    name = lib.mkOption {
      description = "Node Name.";
      type = lib.types.str;
    };
    secretsDir = lib.mkOption {
      description = "Path to the secrets directory for this node.";
      type = lib.types.path;
      default = ./.;
    };
  };
  config = {
    node.name = lib.mkForce "drugstore";
    swarselsystems = {
      info = "~SwarselSystems~ installer ISO";
    };
    home-manager.users."${primaryUser}" = {
      home = {
        stateVersion = "23.05";
        file = {
          ".bash_history" = {
            source = self + /programs/bash/.bash_history;
          };
        };
      };
      swarselsystems = {
        modules.general = lib.mkForce true;
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

    services.getty.autologinUser = lib.mkForce primaryUser;

    users = {
      allowNoPasswordLogin = true;
      groups.swarsel = { };
      users = {
        swarsel = {
          name = primaryUser;
          group = primaryUser;
          isNormalUser = true;
          password = "setup"; # this is overwritten after install
          openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);
          extraGroups = [ "wheel" ];
        };
        root = {
          # password = lib.mkForce config.users.users.swarsel.password; # this is overwritten after install
          openssh.authorizedKeys.keys = config.users.users."${primaryUser}".openssh.authorizedKeys.keys;
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
        mkdir -p -m=0777 /home/${primaryUser}/.local/state/nix/profiles
        mkdir -p -m=0777 /home/${primaryUser}/.local/state/home-manager/gcroots
        mkdir -p -m=0777 /home/${primaryUser}/.local/share/nix/
        printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' | tee /home/${primaryUser}/.local/share/nix/trusted-settings.json > /dev/null
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
  };
}
