{ self, lib, pkgs, config, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir xdgDir;
  owner = mainUser;
  sopsFile = self + /secrets/work/secrets.yaml;
  swarselService = name: description: execStart: {
    "${name}" = {
      enable = true;
      inherit description;
      serviceConfig = {
        ExecStart = execStart;
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
  };
in
{
  options.swarselsystems = {
    modules.optional.work = lib.mkEnableOption "optional work settings";
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    fqdn = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
  config = lib.mkIf config.swarselsystems.modules.optional.work {
    sops =
      let
        secretNames = [
          "vcuser"
          "vcpw"
          "govcuser"
          "govcpw"
          "govcurl"
          "govcdc"
          "govcds"
          "govchost"
          "govcnetwork"
          "govcpool"
        ];
      in
      {
        secrets = builtins.listToAttrs (
          map
            (name: {
              inherit name;
              value = { inherit owner sopsFile; };
            })
            secretNames
        );
      };

    boot.initrd = {
      systemd.enable = lib.mkForce true; # make sure we are using initrd systemd even when not using Impermanence
      luks = {
        # disable "support" since we use systemd-cryptenroll
        # make sure yubikeys are enrolled using
        # sudo systemd-cryptenroll --fido2-device=auto --fido2-with-user-verification=no --fido2-with-user-presence=true --fido2-with-client-pin=no /dev/nvme0n1p2
        yubikeySupport = false;
        fido2Support = false;
      };
    };

    programs = {
      zsh.shellInit = ''
        export VSPHERE_USER="$(cat ${config.sops.secrets.vcuser.path})"
        export VSPHERE_PW="$(cat ${config.sops.secrets.vcpw.path})"
        export GOVC_USERNAME="$(cat ${config.sops.secrets.govcuser.path})"
        export GOVC_PASSWORD="$(cat ${config.sops.secrets.govcpw.path})"
        export GOVC_URL="$(cat ${config.sops.secrets.govcurl.path})"
        export GOVC_DATACENTER="$(cat ${config.sops.secrets.govcdc.path})"
        export GOVC_DATASTORE="$(cat ${config.sops.secrets.govcds.path})"
        export GOVC_HOST="$(cat ${config.sops.secrets.govchost.path})"
        export GOVC_RESOURCE_POOL="$(cat ${config.sops.secrets.govcpool.path})"
        export GOVC_NETWORK="$(cat ${config.sops.secrets.govcnetwork.path})"
      '';

      browserpass.enable = true;
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "${mainUser}" ];
      };
    };

    networking = {
      inherit (config.swarselsystems) hostName fqdn;
      networkmanager.wifi.scanRandMacAddress = false;
      firewall = {
        enable = lib.mkDefault true;
        trustedInterfaces = [ "virbr0" ];
      };
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
      stable24_11.python39
      qemu
      packer
      gnumake
      libisoburn
      govc
      terraform
      opentofu
      terragrunt
      graphviz
      azure-cli

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
          "moonside@oracle" = {
            id = "VPCDZB6-MGVGQZD-Q6DIZW3-IZJRJTO-TCC3QUQ-2BNTL7P-AKE7FBO-N55UNQE";
          };
          folders = {
            "Documents" = {
              path = "${homeDir}/Documents";
              devices = [ "magicant" "winters" "moonside@oracle" ];
              id = "hgr3d-pfu3w";
            };
          };
        };
      };

      udev.extraRules = ''
        # share screen when dongle detected
        SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="343c", ATTRS{idProduct}=="0000", TAG+="systemd", ENV{SYSTEMD_WANTS}="swarsel-screenshare.service"

        # lock screen when yubikey removed
        ACTION=="remove", ENV{PRODUCT}=="3/1050/407/110", RUN+="${pkgs.systemd}/bin/systemctl suspend"
      '';

    };

    systemd.services = lib.mkMerge [
      (swarselService "swarsel-screenshare" "Start screensharing after HDMI dongle is detected" "${pkgs.screenshare}/bin/screenshare -h")
    ];

    # cgroups v1 is required for centos7 dockers
    # specialisation = {
    #   cgroup_v1.configuration = {
    #     boot.kernelParams = [
    #       "SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
    #       "systemd.unified_cgroup_hierarchy=0"
    #     ];
    #   };
    # };
  };

}
