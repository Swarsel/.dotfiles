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

    users.groups.lxc_shares = {
      gid = 10000;
      members = [
        "transmission"
        "root"
      ];
    };

    services.xserver = {
      layout = "us";
      xkbVariant = "altgr-intl";
    };

    nix.settings.experimental-features = ["nix-command" "flakes"];

    sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
    sops.defaultSopsFile = "/.dotfiles/secrets/transmission/secrets.yaml";
    sops.validateSopsFiles = false;

    proxmoxLXC.manageNetwork = true; # manage network myself
    proxmoxLXC.manageHostName = false; # manage hostname myself
    networking.hostName = "transmission"; # Define your hostname.
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

    sops.secrets.vpnuser = {};
    sops.secrets.vpnpass = {};
    sops.secrets.vpnprot = {};
    sops.secrets.vpnport = {};
    sops.secrets.vpnloc = {};
    sops.secrets.crlpem = {};
    sops.secrets.capem = {};
    sops.templates."vpn.config".content = ''
      client
      dev tun
      proto ${config.sops.placeholder.vpnprot}
      remote ${config.sops.placeholder.vpnloc} ${config.sops.placeholder.vpnport}
      resolv-retry infinite
      nobind
      persist-key
      persist-tun
      cipher aes-128-cbc
      auth sha1
      tls-client
      remote-cert-tls server

      auth-user-pass
      compress
      verb 1
      reneg-sec 0

      <crl-verify>
      -----BEGIN X509 CRL-----
      ${config.sops.placeholder.crlpem}
      -----END X509 CRL-----
      </crl-verify>

      <ca>
      -----BEGIN CERTIFICATE-----
      ${config.sops.placeholder.capem}
      -----END CERTIFICATE-----

      </ca>

      disable-occ
    '';
services.openvpn.servers = {
  pia = {
    autoStart = true;
    # Note that this is bad security practise, because the details
    # will be available in the nix store for everyone to see.
    # https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes
    authUserPass = {
      username = "TODO:secrets";
      password = "TODO:secrets";
    };
    # Most of these options came from the OVPN file from the generator
    config = "config ${config.sops.templates."vpn.config".path}";
  };
};


  }
