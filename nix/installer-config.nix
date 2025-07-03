{ pkgs, lib, ... }:
{

  config = {
    home-manager.users.root.home = {
      stateVersion = "23.05";
      file = {
        ".bash_history" = {
          text = ''
            swarsel-install -n chaostheatre
          '';
        };
      };
    };

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };

    boot = {
      supportedFilesystems = lib.mkForce [ "brtfs" "vfat" ];
      loader.systemd-boot = {
        enable = true;
      };
    };

    services = {
      qemuGuest.enable = true;
      openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
        authorizedKeysFiles = lib.mkForce [
          "/etc/ssh/authorized_keys.d/%u"
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      curl
      git
      gnupg
      rsync
      ssh-to-age
      sops
      vim
      just
      sbctl
    ];

    programs = {
      git.enable = true;
    };

    fileSystems."/boot".options = [ "umask=0077" ];

    environment.etc."issue".text = ''
      [32m~SwarselSystems~[0m
                               IP of primary interface: [31m\4[0m
                                                                   The Password for all users & root is '[31msetup[0m'.
                                                                   Install the system remotely by running '[33mbootstrap -n <CONFIGURATION_NAME> -d <IP_FROM_ABOVE> [0m' on a machine with deployed secrets.
                                                                   Alternatively, run '[33mswarsel-install -n <CONFIGURATION_NAME>[0m' for a local install. For your convenience, an example call is in the bash history (press up on the keyboard to access).
    '';

    networking = {
      hostName = "drugstore";
      wireless.enable = false;
      dhcpcd.runHook = "${pkgs.utillinux}/bin/agetty --reload";
      networkmanager.enable = true;
    };

    services.getty.autologinUser = lib.mkForce "root";

    users = {
      allowNoPasswordLogin = true;
      users = {
        root = {
          password = "setup"; # this is overwritten after install
          initialHashedPassword = lib.mkForce null;
          openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDd0XXoLfRE0AyasxscEBwMqOnLWPqwz+etGqzVNeSw/RcgnxOi903mlVjCH+jzWMSe2GVSgzgM20j/r9sfE2P1z+wq/RODFS04JM0ltUoFkkm/IDZXQ2piOk7AoVi5ajdx4EiBnXY87jvxh5cCgQltkj3ouPF7FVN/MaN21IgWYB8NgkaVGft//OplodlDQNot17c0sFMibY0HcquwmHhqKOtKM1gT98+jZl0rd1rCqXFOvkesW6FPC4nzirPai+Hizp5gncrkJOZmLLqrjVx6PfpQzqzIhoUn1YS5CpyfXnKZUgx2Oi8SENmWOZ9DxYvDklgEttob37E2bIXbUhOw/u4I3olGFgCsKL6jg0N+d5teEaCZFnzlOp0UMWiUo7lVqq7Bwl3rNka2pxEdZ9v/1+m9cJiP7h6pnKmccVGku57iGIDnsnoTrmo1qbAje+EsmPYbc+qMnTDvOdSHTOXnjsyTd+ADklvMHCUAuf6ku4ktQEhlZxU3PvYvKHa1cTCEXxLWjytIgHgTgab9M5IH29Q55LSRRQBzUdkwjOG6KhsqG+xEE6038EbXr0MGKTm01AFmeVZWewmkSLu2UdoOMiw8mTSQhQFfp2QruYHnh7oJCo7ttKT1sLoRX+TfgQm1ryn/orhReg2GFfmbiLGxaJGVNvjqCxqrIFQXx4ZDHw== cardno:22_412_399" ];
        };
      };
    };

    programs.bash.shellAliases = {
      "swarsel-install" = "nix run github:Swarsel/.dotfiles#swarsel-install --";
    };

    system.activationScripts.cache = {
      text = ''
          mkdir -p -m=0777 /home/setup/.local/state/nix/profiles
        mkdir -p -m=0777 /home/setup/.local/state/home-manager/gcroots
        mkdir -p -m=0777 /home/setup/.local/share/nix/
        printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' | tee /home/setup/.local/share/nix/trusted-settings.json > /dev/null
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

  };
}
