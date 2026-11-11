{
  self,
  root,
  config,
  lib,
  pkgs,
  ...
}:
let
  pubKeys = lib.filesystem.listFilesRecursive (root "files/public/ssh");
  stateVersion = lib.mkDefault "23.05";
  isSdImage = config.boot.loader.generic-extlinux-compatible.enable;
  userHome = config.users.users.swarsel.home;
  stablePkgs = import self.inputs.nixpkgs-stable26_05 { inherit (pkgs.stdenv.hostPlatform) system; };
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
          "%h/.ssh/authorized_keys"
        ];
        settings.PermitRootLogin = "yes";
      };
      qemuGuest.enable = true;
      xserver.xkb.layout = "us";
    };
    programs = {
      bash.shellAliases = {
        swarsel-kernel-module = "lspci -k -d";
        swarsel-net-manufacturer = "lspci -nn | grep -i 'network\\|ethernet'";
      };
      git.enable = true;
    };
    boot = {
      loader.systemd-boot.enable = !isSdImage;
      supportedFilesystems = lib.mkForce [
        "btrfs"
        "vfat"
      ];
    };
    console.keyMap = "us";
    environment = {
      etc.issue.text = ''
        [32m${self.pii.files.secrets.repo.pii.names.installer}[0m
        IP of primary interface: [31m\4[0m
        These IPs were also found: \4{eth0} \4{eth1} \4{eth2} \4{eth3} \4{eth4} \4{eth5} \4{wlan0}
        The Password for all users & root is '[31msetup[0m'.
        Install the system remotely by running '[33mswarsel-bootstrap <CONFIGURATION_NAME> <IP_FROM_ABOVE>[0m' on a machine with deployed secrets.
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
    fileSystems."/boot" = lib.mkIf (!isSdImage) { options = [ "umask=0077" ]; };
    home-manager.users = {
      root.home = {
        inherit stateVersion;
      };
      swarsel.home = {
        inherit stateVersion;
        homeDirectory = lib.mkDefault userHome;
        sessionVariables.FLAKE = "${userHome}/.dotfiles";
        username = "swarsel";
      };
    };
    networking = {
      hostName = "drugstore";
      networkmanager = {
        enable = true;
        ensureProfiles.profiles = lib.listToAttrs (
          lib.genList (
            index:
            let
              parent = "eth${toString index}";
              inherit (self.outputs.globals.${pkgs.stdenv.hostPlatform.system}.networks.home-lan.vlans.home) id;
            in
            lib.nameValuePair "vlan-home-${parent}" {
              connection = {
                autoconnect = true;
                id = "vlan-home-${parent}";
                interface-name = "${parent}.${toString id}";
                type = "vlan";
              };
              ipv4.method = "auto";
              ipv6.method = "auto";
              vlan = {
                inherit id parent;
              };
            }
          ) 8
        );
      };
      usePredictableInterfaceNames = false;
      wireless.enable = lib.mkForce false;
    };
    nix = {
      package = stablePkgs.nixVersions.nix_2_30;
      channel.enable = false;
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
    system.stateVersion = lib.mkForce "23.05";
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
