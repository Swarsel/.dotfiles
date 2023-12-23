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
    cifs-utils
  ];

  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
  sops.defaultSopsFile = "/.dotfiles/secrets/calibre/secrets.yaml";
  sops.validateSopsFiles = false;
  sops.secrets.smbuser = { };
  sops.secrets.smbpassword = { };
  sops.secrets.smbdomain = { };
  sops.templates."smb.cred".content = ''
  user=${config.sops.placeholder.smbuser}
  password=${config.sops.placeholder.smbpassword}
  domain=${config.sops.placeholder.smbdomain}
  '';
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

  fileSystems."/media/books" = {
    device = "//192.168.1.3/Eternor/Books";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=${config.sops.templates."smb.cred".path},uid=0,iocharset=utf8,vers=2.0,noperm"];
  };

#   services.calibre-server = {
#     enable = true;
#     user = "bookuser";
#     auth.enable = true;
#     auth.userDb = "/srv/calibre/users.sqlite";
#     libraries = [
#       /media/books/Books/calibre/main
#       /media/books/Books/calibre/diverse
#       /media/books/Books/calibre/language
#       /media/books/Books/calibre/science
#       /media/books/Books/calibre/sport
#       /media/books/Books/calibre/novels
#     ];
#   };

}
