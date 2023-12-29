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
  ];

  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
  # sops.defaultSopsFile = "/.dotfiles/secrets/matrix/secrets.yaml";
  # sops.validateSopsFiles = false;

  proxmoxLXC.manageNetwork = true; # manage network myself
  proxmoxLXC.manageHostName = false; # manage hostname myself
  networking.hostName = "matrix"; # Define your hostname.
  networking.useDHCP = true;
  networking.enableIPv6 = false;
  networking.firewall.enable = false;
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
  # users.users.root.password = "TEMPLATE";

  environment.shellAliases = {
    nswitch = "cd /.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
  };


}
