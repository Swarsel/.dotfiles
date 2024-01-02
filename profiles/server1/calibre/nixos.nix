{ config, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    gnupg
    ssh-to-age
    calibre
  ];

  users.groups.lxc_shares = {
    gid = 10000;
    members = [
            "kavita"
            "calibre-web"
            "root"
          ];
  };

  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
  sops.defaultSopsFile = "/.dotfiles/secrets/calibre/secrets.yaml";
  sops.validateSopsFiles = false;
  sops.secrets.kavita = { owner = "kavita";};
  # sops.secrets.smbuser = { };
  # sops.secrets.smbpassword = { };
  # sops.secrets.smbdomain = { };
  # sops.templates."smb.cred".content = ''
  # user=${config.sops.placeholder.smbuser}
  # password=${config.sops.placeholder.smbpassword}
  # domain=${config.sops.placeholder.smbdomain}
  # '';
  proxmoxLXC.manageNetwork = true; # manage network myself
  proxmoxLXC.manageHostName = false; # manage hostname myself
  networking.hostName = "calibre"; # Define your hostname.
  networking.useDHCP = true;
  networking.enableIPv6 = false;
  networking.firewall.enable = false;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../../secrets/keys/authorized_keys
  ];

  system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change

  environment.shellAliases = {
    nswitch = "cd /.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
  };


    # services.calibre-server = {
    # enable = true;
    # user = "calibre-server";
    # auth.enable = true;
    # auth.userDb = "/srv/calibre/users.sqlite";
    # libraries = [
    #   /media/Books/main
    #   /media/Books/diverse
    #   /media/Books/language
    #   /media/Books/science
    #   /media/Books/sport
    #   /media/Books/novels
    # ];
  # };

  # services.calibre-web = {
  #   enable = true;
  #   user = "calibre-web";
  #   group = "calibre-web";
  #   listen.port = 8083;
  #   listen.ip = "0.0.0.0";
  #   options = {
  #     enableBookUploading = true;
  #     enableKepubify = true;
  #     enableBookConversion = true;
  #   };
  # };

  services.kavita = {
    enable = true;
    user = "kavita";
    port = 8080;
    tokenKeyFile = config.sops.secrets.kavita.path;
  };


}
