{ pkgs, config, ... }:
{
  sops = {
    secrets = {
      clad = {
        owner = "swarsel";
        sopsFile = ../../../secrets/work/secrets.yaml;
      };
      dcad = {
        owner = "swarsel";
        sopsFile = ../../../secrets/work/secrets.yaml;
      };
      wsad = {
        owner = "swarsel";
        sopsFile = ../../../secrets/work/secrets.yaml;
      };
      imbad = {
        owner = "swarsel";
        sopsFile = ../../../secrets/work/secrets.yaml;
      };
    };
  };

  # boot.initrd.luks.yubikeySupport = true;
  programs = {
    zsh.shellInit = ''
      export CLAD="$(cat ${config.sops.secrets.clad.path})"
      export DCAD="$(cat ${config.sops.secrets.dcad.path})"
      export GOVC_PASSWORD="$(cat ${config.sops.secrets.dcad.path})"
      export WSAD="$(cat ${config.sops.secrets.wsad.path})"
      export IMBAD="$(cat ${config.sops.secrets.imbad.path})"
      export DCUSER="dc_adm_schwarzaeugl@IMP.UNIVIE.AC.AT"
      export GOVC_USERNAME="dc_adm_schwarzaeugl@IMP.UNIVIE.AC.AT"
      export PACKER_SSH_EXTRA_ARGS='"--scp-extra-args","'-O'"'
    '';

    browserpass.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "swarsel" ];
    };
  };

  virtualisation = {
    docker.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [(pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd];
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # (python39.withPackages (ps: with ps; [
    # cryptography
    # ]))
    #   docker
    python39
    qemu
    packer
    gnumake
    libisoburn
    govc
    terraform
  ];


  services = {
    openssh = {
      enable = true;
      extraConfig = ''
        '';
    };

    syncthing = {
      settings = {
        "winters" = {
          id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
        };
        folders = {
          "Documents" = {
            path = "/home/swarsel/Documents";
            devices = [ "magicant" "winters" ];
            id = "hgr3d-pfu3w";
          };
        };
      };
    };
  };

  # cgroups v1 is required for centos7 dockers
  specialisation = {
    cgroup_v1.configuration = {
      boot.kernelParams = [
        "SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
        "systemd.unified_cgroup_hierarchy=0"
      ];
    };
  };

}
