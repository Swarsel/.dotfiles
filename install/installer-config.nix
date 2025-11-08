{ self, config, pkgs, lib, ... }:
let
  pubKeys = lib.filesystem.listFilesRecursive "${self}/secrets/keys/ssh";
in
{

  config = {
    home-manager.users.root.home = {
      stateVersion = "23.05";
      file = {
        ".bash_history" = {
          text = ''
            swarsel-install -n hotel
          '';
        };
      };
    };
    home-manager.users.swarsel = {
      home = {
        username = "swarsel";
        homeDirectory = lib.mkDefault "/home/swarsel";
        stateVersion = lib.mkDefault "23.05";
        keyboard.layout = "us";
        sessionVariables = {
          FLAKE = "/home/swarsel/.dotfiles";
        };
        file = {
          ".bash_history" = {
            text = ''
              swarsel-install -n hotel
            '';
          };
        };
      };
    };

    security.sudo.extraConfig = ''
      Defaults    env_keep+=SSH_AUTH_SOCK
      Defaults lecture = never
    '';
    security.pam = {
      sshAgentAuth.enable = true;
      services = {
        sudo.u2fAuth = true;
      };
    };

    nix = {
      channel.enable = false;
      package = pkgs.nixVersions.nix_2_28;
      # extraOptions = ''
      #   plugin-files = ${pkgs.dev.nix-plugins}/lib/nix/plugins
      #   extra-builtins-file = ${../nix/extra-builtins.nix}
      # '';
      extraOptions = ''
        plugin-files = ${pkgs.nix-plugins.overrideAttrs (o: {
          buildInputs = [config.nix.package pkgs.boost];
          patches = o.patches or [];
        })}/lib/nix/plugins
        extra-builtins-file = ${../nix/extra-builtins.nix}
      '';

      settings.experimental-features = [ "nix-command" "flakes" ];
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
      networkmanager
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
      # dhcpcd.runHook = "${pkgs.utillinux}/bin/agetty --reload";
      networkmanager.enable = true;
    };

    services.getty.autologinUser = lib.mkForce "root";

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
          initialHashedPassword = lib.mkForce null;
          password = lib.mkForce config.users.users.swarsel.password; # this is overwritten after install
          openssh.authorizedKeys.keys = config.users.users.swarsel.openssh.authorizedKeys.keys;
        };
      };
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

  };
}
