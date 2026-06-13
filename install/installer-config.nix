{ self, config, pkgs, lib, ... }:
let
  pubKeys = lib.filesystem.listFilesRecursive "${self}/files/public/ssh";
  stateVersion = lib.mkDefault "23.05";
  homeFiles = {
    ".bash_history" = {
      text = ''
        swarsel-install -n hotel
      '';
    };
  };
  trustedSettings = builtins.toJSON {
    extra-substituters = {
      "https://nix-community.cachix.org" = true;
      "https://nix-community.cachix.org https://cache.ngi0.nixos.org/" = true;
    };
    extra-trusted-public-keys = {
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" = true;
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=" = true;
    };
  };
in
{

  config = {
    home-manager.users = {
      root.home = {
        inherit stateVersion;
        file = homeFiles;
      };
      swarsel.home = {
        username = "swarsel";
        homeDirectory = lib.mkDefault "/home/swarsel";
        inherit stateVersion;
        sessionVariables = {
          FLAKE = "/home/swarsel/.dotfiles";
        };
        file = homeFiles;
      };
    };

    console.keyMap = "us";

    security = {
      sudo.extraConfig = ''
        Defaults env_keep+=SSH_AUTH_SOCK
        Defaults lecture = never
      '';
      pam.sshAgentAuth.enable = true;
    };

    nix = {
      channel.enable = false;
      package = pkgs.nixVersions.nix_2_28;
      extraOptions = ''
        plugin-files = ${pkgs.nix-plugins.overrideAttrs (o: {
          buildInputs = [config.nix.package pkgs.boost];
          patches = o.patches or [];
        })}/lib/nix/plugins
        extra-builtins-file = ${../files/nix/extra-builtins.nix}
      '';

      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    boot = {
      supportedFilesystems = lib.mkForce [ "btrfs" "vfat" ];
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
      getty.autologinUser = lib.mkForce "root";
      xserver.xkb.layout = "us";
    };

    environment = {
      systemPackages = with pkgs; [
        curl
        gnupg
        rsync
        ssh-to-age
        sops
        vim
        just
        sbctl
        lsof
        dig

        cryptsetup
        btrfs-progs
      ];

      etc."issue".text = ''
        [32m~SwarselSystems~[0m
        IP of primary interface: [31m\4[0m
        These IPs were also found: \4{eth0} \4{eth1} \4{eth2} \4{eth3} \4{eth4} \4{eth5} \4{wlan0}
        The Password for all users & root is '[31msetup[0m'.
        Install the system remotely by running '[33mbootstrap -n <CONFIGURATION_NAME> -d <IP_FROM_ABOVE> [0m' on a machine with deployed secrets.
        Alternatively, run '[33mswarsel-install -n <CONFIGURATION_NAME>[0m' for a local install. For your convenience, an example call is in the bash history (press up on the keyboard to access).
      '';
    };

    fileSystems."/boot".options = [ "umask=0077" ];

    networking = {
      hostName = "drugstore";
      wireless.enable = lib.mkForce false;
      networkmanager.enable = true;
      usePredictableInterfaceNames = false;
    };

    users = {
      allowNoPasswordLogin = true;
      groups.swarsel = { };
      users = {
        swarsel = {
          name = "swarsel";
          group = "swarsel";
          isNormalUser = true;
          password = "setup"; # this is overwritten after install
          openssh.authorizedKeys.keys = map builtins.readFile pubKeys;
          extraGroups = [ "wheel" ];
        };
        root = {
          initialHashedPassword = lib.mkForce null;
          password = lib.mkForce config.users.users.swarsel.password; # this is overwritten after install
          openssh.authorizedKeys.keys = config.users.users.swarsel.openssh.authorizedKeys.keys;
        };
      };
    };

    programs = {
      git.enable = true;
      bash.shellAliases = {
        "swarsel-install" = "nix run github:Swarsel/.dotfiles#swarsel-install --";
        "swarsel-net-manufacturer" = "lspci -nn | grep -i 'network\\|ethernet'";
        "swarsel-kernel-module" = "lspci -k -d";
      };
    };

    system = {
      activationScripts.cache.text = ''
        mkdir -p -m=0777 /home/swarsel/.local/state/nix/profiles
        mkdir -p -m=0777 /home/swarsel/.local/state/home-manager/gcroots
        mkdir -p -m=0777 /home/swarsel/.local/share/nix/
        mkdir -p /root/.local/share/nix/
        src=${pkgs.writeText "trusted-settings.json" trustedSettings}
        install -m 0644 $src /home/swarsel/.local/share/nix/trusted-settings.json
        install -m 0644 $src /root/.local/share/nix/trusted-settings.json
      '';
      stateVersion = lib.mkForce "23.05";
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

  };
}
