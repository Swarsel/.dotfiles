{ config, pkgs, modulesPath, ... }:

{
  
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./hardware-configuration.nix
  ];
  
  
  
  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };
  nix.settings.experimental-features = ["nix-command" "flakes"];
  proxmoxLXC.manageNetwork = true; # manage network myself
  proxmoxLXC.manageHostName = false; # manage hostname myself
  networking.useDHCP = true;
  networking.enableIPv6 = false;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    listenAddresses = [{
      port = 22;
      addr = "0.0.0.0";
    }];
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../../secrets/keys/authorized_keys
  ];
  
  system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change
  
  environment.shellAliases = {
    nswitch = "cd /.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
  };
  
  

  proxmoxLXC.privileged = true; # manage hostname myself

  users.groups.lxc_pshares = {
    gid = 110000;
    members = [
      "navidrome"
      "mpd"
      "root"
    ];
  };

  users.groups.navidrome = {
    gid = 61593;
  };

  users.groups.mpd = {};

  users.users.navidrome = {
    isSystemUser = true;
    uid = 61593;
    group = "navidrome";
    extraGroups  = [ "audio" "utmp" ];
  };

  users.users.mpd = {
    isSystemUser = true;
    group = "mpd";
    extraGroups  = [ "audio" "utmp" ];
  };

  sound = {
    enable = true;
  };

  hardware.enableAllFirmware = true;
  networking.hostName = "sound"; # Define your hostname.
  networking.firewall.enable = false;
  environment.systemPackages = with pkgs; [
    git
    gnupg
    ssh-to-age
    pciutils
    alsa-utils
    mpv
  ];

  sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
  sops.defaultSopsFile = "/.dotfiles/secrets/sound/secrets.yaml";
  sops.validateSopsFiles = false;
  sops.secrets.mpdpass = { owner = "mpd";};

  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4040;
      MusicFolder = "/media";
      EnableSharing = true;
      EnableTranscodingConfig = true;
      Scanner.GroupAlbumReleases = true;
      ScanSchedule = "@every 1d";
      # Insert these values locally as sops-nix does not work for them
      LastFM.ApiKey = TEMPLATE;
      LastFM.Secret = TEMPLATE;
      Spotify.ID = TEMPLATE;
      Spotify.Secret = TEMPLATE;
      UILoginBackgroundUrl = "https://i.imgur.com/OMLxi7l.png";
      UIWelcomeMessage = "~SwarselSound~";
    };
  };
  services.mpd = {
    enable = true;
    musicDirectory = "/media";
    user = "mpd";
    group = "mpd";
    network = {
      port = 3254;
      listenAddress = "any";
    };
    credentials = [
      {
        passwordFile = config.sops.secrets.mpdpass.path;
        permissions = [
          "read"
          "add"
          "control"
          "admin"
        ];
      }
    ];
  };
}
