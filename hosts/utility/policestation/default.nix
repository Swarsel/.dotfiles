{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    users.users.nixos = {
      extraGroups = [ "wheel" ];
      initialHashedPassword = "";
      isNormalUser = true;
    };
    services = {
      getty.autologinUser = "nixos";
      pcscd.enable = true;
      udev.packages = [ pkgs.yubikey-personalization ];
    };
    programs = {
      gnupg = {
        agent = {
          enable = true;
          enableSSHSupport = true;
        };
        dirmngr.enable = true;
      };
      ssh.startAgent = false;
    };
    boot = {
      initrd.network.enable = false;
      kernel.sysctl."kernel.unprivileged_bpf_disabled" = 1;
      tmp.cleanOnBoot = true;
    };
    environment = {
      interactiveShellInit = ''
        unset HISTFILE
          export GNUPGHOME="/run/user/$(id -u)/gnupg"
          if [ ! -d "$GNUPGHOME" ]; then
            install -m=0700 --directory="$GNUPGHOME"
          fi
          [ ! -f "$GNUPGHOME/gpg.conf" ] && cp /home/nixos/gpg-hardened.conf "$GNUPGHOME/gpg.conf"
          [ ! -f "$GNUPGHOME/gpg-agent.conf" ] && cp /home/nixos/gpg-agent.conf "$GNUPGHOME/gpg-agent.conf"
      '';
      systemPackages = with pkgs; [
        paperkey
        pgpdump
        parted
        cryptsetup
        yubikey-manager
        yubikey-personalization
        pcsc-tools
      ];
    };
    home-manager.users.nixos = {
      services.gpg-agent = {
        enable = true;
        defaultCacheTtl = 60;
        enableBashIntegration = true;
        enableSshSupport = true;
        maxCacheTtl = 120;
        pinentry = {
          package = pkgs.pinentry-curses;
          program = "pinentry-curses";
        };
      };
      programs.gpg.enable = true;
      home = {
        inherit (config.system) stateVersion;
        file.".gnupg/gpg-hardened.conf".text = ''
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
        homeDirectory = "/home/nixos";
        keyboard.layout = "us";
        username = "nixos";
      };
    };
    networking = {
      dhcpcd = {
        enable = false;
        allowInterfaces = [ ];
      };
      firewall.enable = true;
      hostName = "policestation";
      interfaces = { };
      networkmanager.enable = lib.mkForce false;
      resolvconf.enable = false;
      useDHCP = false;
      useNetworkd = false;
      wireless.enable = false;
    };
    nix = {
      channel.enable = false;
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    swapDevices = [ ];
    system.stateVersion = lib.mkForce "23.05";
    systemd.targets = {
      hibernate.enable = false;
      hybrid-sleep.enable = false;
      sleep.enable = false;
      suspend.enable = false;
    };
  };
}
