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

  # nixpkgs.overlays = [
  #   self: super: {
  #     airsonic = super.airsonic.overrideAttrs (_: rec {
  #       version = "11.0.2-kagemomiji";
  #       name = "airsonic-advanced-${version}";
  #       src = super.fetchurl {
  #         url = "https://github.com/kagemomiji/airsonic-advanced/releases/download/11.0.2/airsonic.war";
  #         sha256 = "PgErtEizHraZgoWHs5jYJJ5NsliDd9VulQfS64ackFo=";
  #       };
  #     });
  #   }];

  # services.airsonic = {
    # enable = true;
    # user = "airsonic";
    # listenAddress = "0.0.0.0";
    # port = 4040;
    # jre = pkgs.jdk17;
  #};

  services.gonic = {
    enable = true;
    {
      cache-path = "/var/cache/gonic";
      listen-addr = "0.0.0.0:4040";
      music-path = ["/media"];
      jukebox-enabled = true;
    }
  }

}
