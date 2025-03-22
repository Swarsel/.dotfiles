{ self, lib, pkgs, config, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir xdgDir;
  owner = mainUser;
  sopsFile = self + /secrets/work/secrets.yaml;
in
{
  sops = {
    secrets = {
      vcuser = {
        inherit owner sopsFile;
      };
      vcpw = {
        inherit owner sopsFile;
      };
    };
  };

  # boot.initrd.luks.yubikeySupport = true;
  programs = {
    zsh.shellInit = ''
      export VSPHERE_USER="$(cat ${config.sops.secrets.vcuser.path})"
      export VSPHERE_PW="$(cat ${config.sops.secrets.vcpw.path})"
    '';

    browserpass.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "${mainUser}" ];
    };
  };

  networking = {
    firewall.trustedInterfaces = [ "virbr0" ];
    search = [
      "vbc.ac.at"
      "clip.vbc.ac.at"
      "imp.univie.ac.at"
    ];
  };

  virtualisation = {
    docker.enable = lib.mkIf (!config.virtualisation.podman.dockerCompat) true;
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = with pkgs; [ virtiofsd ];
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMFFull.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
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
    graphviz

    # vm
    virt-manager
    virt-viewer
    virtiofsd
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
  ];


  services = {
    spice-vdagentd.enable = true;
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
            path = "${homeDir}/Documents";
            devices = [ "magicant" "winters" ];
            id = "hgr3d-pfu3w";
          };
        };
      };
    };

    udev.extraRules = ''
      SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="04e8", ATTRS{idProduct}=="6860", TAG+="systemd", ENV{SYSTEMD_WANTS}="swarsel-screenshare.service"
    '';

  };

  systemd.services.swarsel-screenshare = {
    enable = true;
    description = "Screensharing service upon dongle plugin";
    serviceConfig = {
      ExecStart = "${pkgs.screenshare}/bin/screenshare -h";
      User = mainUser;
      Group = "users";
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${mainUser}/bin"
        "XDG_RUNTIME_DIR=${xdgDir}"
        "WAYLAND_DISPLAY=wayland-1"
      ];
      Type = "oneshot";
      StandardOutput = "journal";
      StandardError = "journal";
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
