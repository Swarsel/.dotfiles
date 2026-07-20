{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  pubKeys = lib.filesystem.listFilesRecursive "${self}/files/public/ssh";
  stateVersion = lib.mkDefault "23.05";
  homeFiles = {
    ".bash_history".text = ''
      swarsel-install -n hotel
    '';
  };
  trustedSettings = builtins.toJSON {
    extra-substituters = {
      "https://nix-community.cachix.org" = true;
      "https://nix-community.cachix.org https://cache.ngi0.nixos.org/" = true;
    };
    extra-trusted-public-keys = {
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" = true;
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=" =
        true;
    };
  };
in
{

  config = {
    users = {
      users = {
        root = {
          initialHashedPassword = lib.mkForce null;
          openssh.authorizedKeys.keys = config.users.users.swarsel.openssh.authorizedKeys.keys;
          password = lib.mkForce config.users.users.swarsel.password; # this is overwritten after install
        };
        swarsel = {
          extraGroups = [ "wheel" ];
          group = "swarsel";
          isNormalUser = true;
          name = "swarsel";
          openssh.authorizedKeys.keys = map builtins.readFile pubKeys;
          password = "setup"; # this is overwritten after install
        };
      };
      allowNoPasswordLogin = true;
      groups.swarsel = { };
    };
    services = {
      getty.autologinUser = lib.mkForce "root";
      openssh = {
        enable = true;
        authorizedKeysFiles = lib.mkForce [
          "/etc/ssh/authorized_keys.d/%u"
        ];
        settings.PermitRootLogin = "yes";
      };
      qemuGuest.enable = true;
      xserver.xkb.layout = "us";
    };
    programs = {
      bash.shellAliases = {
        "swarsel-install" = "nix run github:Swarsel/.dotfiles#swarsel-install --";
        "swarsel-kernel-module" = "lspci -k -d";
        "swarsel-net-manufacturer" = "lspci -nn | grep -i 'network\\|ethernet'";
      };
      git.enable = true;
    };
    boot = {
      loader.systemd-boot.enable = true;
      supportedFilesystems = lib.mkForce [
        "btrfs"
        "vfat"
      ];
    };
    console.keyMap = "us";
    environment = {
      etc."issue".text = ''
        [32m~SwarselSystems~[0m
        IP of primary interface: [31m\4[0m
        These IPs were also found: \4{eth0} \4{eth1} \4{eth2} \4{eth3} \4{eth4} \4{eth5} \4{wlan0}
        The Password for all users & root is '[31msetup[0m'.
        Install the system remotely by running '[33mbootstrap -n <CONFIGURATION_NAME> -d <IP_FROM_ABOVE> [0m' on a machine with deployed secrets.
        Alternatively, run '[33mswarsel-install -n <CONFIGURATION_NAME>[0m' for a local install. For your convenience, an example call is in the bash history (press up on the keyboard to access).
      '';
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
    };
    fileSystems."/boot".options = [ "umask=0077" ];
    home-manager.users = {
      root.home = {
        inherit stateVersion;
        file = homeFiles;
      };
      swarsel.home = {
        inherit stateVersion;
        file = homeFiles;
        homeDirectory = lib.mkDefault "/home/swarsel";
        sessionVariables.FLAKE = "/home/swarsel/.dotfiles";
        username = "swarsel";
      };
    };
    networking = {
      hostName = "drugstore";
      networkmanager.enable = true;
      usePredictableInterfaceNames = false;
      wireless.enable = lib.mkForce false;
    };
    nix = {
      package =
        (import self.inputs.nixpkgs-stable26_05 { inherit (pkgs.stdenv.hostPlatform) system; })
        .nixVersions.nix_2_28;
      channel.enable = false;
      extraOptions = ''
        plugin-files = ${
          pkgs.nix-plugins.overrideAttrs (o: {
            buildInputs = [
              config.nix.package
              pkgs.boost
            ];
            patches = o.patches or [ ];
          })
        }/lib/nix/plugins
        extra-builtins-file = ${../../../files/nix/extra-builtins.nix}
      '';
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    security = {
      pam.sshAgentAuth.enable = true;
      sudo.extraConfig = ''
        Defaults env_keep+=SSH_AUTH_SOCK
        Defaults lecture = never
      '';
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
        hibernate.enable = false;
        hybrid-sleep.enable = false;
        sleep.enable = false;
        suspend.enable = false;
      };
    };

  };
}
