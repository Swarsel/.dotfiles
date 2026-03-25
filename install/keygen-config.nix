{ config, pkgs, lib, ... }:
{
  config = {
    home-manager.users.nixos = {
      home = {
        inherit (config.system) stateVersion;
        username = "nixos";
        homeDirectory = "/home/nixos";
        keyboard.layout = "us";
        file.".gnupg/gpg-hardened.conf" = {
          text = ''
            personal-cipher-preferences AES256 AES192 AES
            personal-digest-preferences SHA512 SHA384 SHA256
            personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
            default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
            cert-digest-algo SHA512
            s2k-digest-algo SHA512
            s2k-cipher-algo AES256
            charset utf-8
            no-comments
            no-emit-version
            no-greeting
            keyid-format 0xlong
            list-options show-uid-validity
            verify-options show-uid-validity
            with-fingerprint
            require-cross-certification
            require-secmem
            no-symkey-cache
            armor
            use-agent
            throw-keyids
          '';
        };
      };

      services.gpg-agent = {
        enable = true;
        enableBashIntegration = true;
        enableSshSupport = true;
        pinentry = {
          package = pkgs.pinentry-curses;
          program = "pinentry-curses";
        };
        defaultCacheTtl = 60;
        maxCacheTtl = 120;
      };

      programs.gpg = {
        enable = true;
      };
    };

    programs = {
      ssh.startAgent = false;
      gnupg = {
        dirmngr.enable = true;
        agent = {
          enable = true;
          enableSSHSupport = true;
        };
      };
    };

    swapDevices = [ ];

    services = {
      pcscd.enable = true;
      udev.packages = [ pkgs.yubikey-personalization ];
      getty.autologinUser = "nixos";
    };

    nix = {
      channel.enable = false;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    environment.interactiveShellInit = ''
      unset HISTFILE
        export GNUPGHOME="/run/user/$(id -u)/gnupg"
        if [ ! -d "$GNUPGHOME" ]; then
          install -m=0700 --directory="$GNUPGHOME"
        fi
        [ ! -f "$GNUPGHOME/gpg.conf" ] && cp /home/nixos/gpg-hardened.conf "$GNUPGHOME/gpg.conf"
        [ ! -f "$GNUPGHOME/gpg-agent.conf" ] && cp /home/nixos/gpg-agent.conf "$GNUPGHOME/gpg-agent.conf"
    '';

    environment.systemPackages = with pkgs; [
      paperkey
      pgpdump
      parted
      cryptsetup
      yubikey-manager
      yubikey-personalization
      pcsc-tools
    ];

    boot = {
      initrd.network.enable = false;
      tmp.cleanOnBoot = true;
      kernel.sysctl = {
        "kernel.unprivileged_bpf_disabled" = 1;
      };
    };

    networking = {
      hostName = "policestation";
      resolvconf.enable = false;
      dhcpcd.enable = false;
      dhcpcd.allowInterfaces = [ ];
      interfaces = { };
      firewall.enable = true;
      useDHCP = false;
      useNetworkd = false;
      wireless.enable = false;
      networkmanager.enable = lib.mkForce false;
    };

    users.users.nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialHashedPassword = "";
    };

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    systemd = {
      targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };
    };

    system.stateVersion = lib.mkForce "23.05";
  };
}
