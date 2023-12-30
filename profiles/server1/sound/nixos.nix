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
  
  

  networking.hostName = "sound"; # Define your hostname.
  networking.firewall.enable = false;
  environment.systemPackages = with pkgs; [
    git
    gnupg
    ssh-to-age
  ];

  # sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
  # sops.defaultSopsFile = "/.dotfiles/secrets/sound/secrets.yaml";
  # sops.validateSopsFiles = false;
  users.users.airsonic = {
    extraGroups  = [ "audio" ];
  };

  services.airsonic = {
    enable = true;
    user = "airsonic";
    listenAddress = "0.0.0.0";
    port = 443;
  };

}
