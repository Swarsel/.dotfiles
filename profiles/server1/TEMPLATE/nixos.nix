{ pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  environment.systemPackages = with pkgs; [
    git
    gnupg
    ssh-to-age
  ];

  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  proxmoxLXC.manageNetwork = true; # manage network myself
  proxmoxLXC.manageHostName = true; # manage hostname myself
  networking.hostName = "TEMPLATE"; # Define your hostname.
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
  # users.users.root.password = "TEMPLATE";

  system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change
}
