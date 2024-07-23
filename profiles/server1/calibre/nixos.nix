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

  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/sops" ];
    defaultSopsFile = "/.dotfiles/secrets/calibre/secrets.yaml";
    validateSopsFiles = false;
    secrets.kavita = { owner = "kavita"; };
  };
  proxmoxLXC = {
    manageNetwork = true; # manage network myself
    manageHostName = false; # manage hostname myself
  };
  networking = {
    hostName = "calibre"; # Define your hostname.
    useDHCP = true;
    enableIPv6 = false;
    firewall.enable = false;
  };
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

  services.kavita = {
    enable = true;
    user = "kavita";
    port = 8080;
    tokenKeyFile = config.sops.secrets.kavita.path;
  };


}
