{ config, pkgs, modulesPath, ... }:

{

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
      listenAddresses = [{
        port = 22;
        addr = "0.0.0.0";
      }];
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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



  users.groups.lxc_shares = {
    gid = 10000;
    members = [
      "paperless"
      "root"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    gnupg
    ssh-to-age
  ];

  networking = {
    hostName = "paperless"; # Define your hostname.
    firewall.enable = false;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/sops" ];
    defaultSopsFile = "/root/.dotfiles/secrets/paperless/secrets.yaml";
    validateSopsFiles = false;
    secrets.admin = { owner = "paperless"; };
  };

  services.paperless = {
    enable = true;
    mediaDir = "/media";
    user = "paperless";
    port = 28981;
    passwordFile = config.sops.secrets.admin.path;
    address = "0.0.0.0";
    extraConfig = {
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
      PAPERLESS_URL = "scan.swarsel.win";
      PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
  };

}
