{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./hardware-configuration.nix
  ];

  services = {
    xserver = {
      layout = "us";
      xkbVariant = "altgr-intl";
    };
    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
      listenAddresses = [
        {
          port = 22;
          addr = "0.0.0.0";
        }
      ];
    };
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  proxmoxLXC = {
    manageNetwork = true; # manage network myself
    manageHostName = false; # manage hostname myself
  };

  networking = {
    useDHCP = true;
    enableIPv6 = false;
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../../secrets/keys/authorized_keys
  ];

  system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change

  environment.shellAliases = {
    nswitch = "cd /.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
  };

  proxmoxLXC.privileged = true; # manage hostname myself

  users.groups.spotifyd = {
    gid = 65136;
  };

  users.users.spotifyd = {
    isSystemUser = true;
    uid = 65136;
    group = "spotifyd";
    extraGroups = ["audio" "utmp"];
  };

  sound = {
    enable = true;
  };

  hardware.enableAllFirmware = true;
  networking = {
    hostName = "spotifyd"; # Define your hostname.
    firewall.enable = false;
  };
  environment.systemPackages = with pkgs; [
    git
    gnupg
    ssh-to-age
  ];

  services.spotifyd = {
    enable = true;
    settings = {
      global = {
        dbus_type = "session";
        use_mpris = false;
        device = "default:CARD=PCH";
        device_name = "SwarselSpot";
        mixer = "alsa";
        zeroconf_port = 1025;
      };
    };
  };
}
