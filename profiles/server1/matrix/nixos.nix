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

  sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
  sops.defaultSopsFile = "/.dotfiles/secrets/matrix/secrets.yaml";
  sops.validateSopsFiles = false;

  sops.secrets.matrixsharedsecret = {owner="matrix-synapse";};
  sops.templates."matrixshared".owner = "matrix-synapse";
  sops.templates."matrixshared".content = ''
  registration_shared_secret${config.sops.placeholder.matrixsharedsecret}
  '';

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

  services.postgresql.enable = true;
  services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
  CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
  CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
    TEMPLATE template0
    LC_COLLATE = "C"
    LC_CTYPE = "C";
'';

   services.matrix-synapse = {
     enable = true;
     settings.server_name = "matrix.swarsel.win";
     settings.public_baseurl = "https://matrix.swarsel.win";
     extraConfigFiles = [
       config.sops.templates.matrixshared.path
     ];
     settings.listeners = [
       { port = 8008;
         bind_addresses = [ "0.0.0.0" ];
         type = "http";
         tls = false;
         x_forwarded = true;
         resources = [
           {
             names = [ "client" "federation" ];
             compress = true;
           }
         ];
       }
     ];
   };

}
