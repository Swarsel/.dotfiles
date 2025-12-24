{ self, lib, pkgs, config, withHomeManager, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
  iwd = config.networking.networkmanager.wifi.backend == "iwd";
  owner = mainUser;
  sopsFile = self + /secrets/work/secrets.yaml;
in
{
  options.swarselsystems = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = config.node.name;
    };
    fqdn = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
  config = {

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
          "baseuser"
          "basepw"
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
        templates = {
          "network-manager-work.env".content = ''
            BASEUSER=${config.sops.placeholder.baseuser}
            BASEPASS=${config.sops.placeholder.basepw}
          '';
        };
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

      browserpass.enable = true;
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        package = pkgs._1password-gui-beta;
        polkitPolicyOwners = [ "${mainUser}" ];
      };
    };

    networking = {
      inherit (config.swarselsystems) hostName fqdn;

      networkmanager = {
        wifi.scanRandMacAddress = false;
        ensureProfiles = {
          environmentFiles = [
            "${config.sops.templates."network-manager-work.env".path}"
          ];
          profiles = {
            VBC = {
              "802-1x" = {
                eap = if (!iwd) then "ttls;" else "peap;";
                identity = "$BASEUSER";
                password = "$BASEPASS";
                phase2-auth = "mschapv2";
              };
              connection = {
                id = "VBC";
                type = "wifi";
                autoconnect-priority = "500";
                uuid = "3988f10e-6451-381f-9330-a12e66f45051";
                secondaries = "48d09de4-0521-47d7-9bd5-43f97e23ff82"; # vpn uuid
              };
              ipv4 = { method = "auto"; };
              ipv6 = {
                # addr-gen-mode = "default";
                addr-gen-mode = "stable-privacy";
                method = "auto";
              };
              proxy = { };
              wifi = {
                cloned-mac-address = "permanent";
                mac-address = "E8:65:38:52:63:FF";
                mac-address-randomization = "1";
                mode = "infrastructure";
                band = "a";
                ssid = "VBC";
              };
              wifi-security = {
                # auth-alg = "open";
                key-mgmt = "wpa-eap";
              };
            };
          };
        };
      };


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
          # ovmf = {
          #   enable = true;
          #   packages = [
          #     (pkgs.OVMFFull.override {
          #       secureBoot = true;
          #       tpmSupport = true;
          #     }).fd
          #   ];
          # };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      remmina
      # gp-onsaml-gui
      stable24_11.python39
      qemu
      packer
      gnumake
      libisoburn
      govc
      terraform
      opentofu
      # dev.terragrunt
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
      virtio-win
      win-spice

      powershell
      gh
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
              devices = [ "moonside@oracle" ];
              id = "hgr3d-pfu3w";
            };
          };
        };
      };

      # ACTION=="remove", ENV{PRODUCT}=="3/1050/407/110", RUN+="${pkgs.kanshi}/bin/kanshictl switch laptoponly"
      udev.extraRules = ''
        # lock screen when yubikey removed
        ACTION=="remove", ENV{PRODUCT}=="3/1050/407/110", RUN+="${pkgs.systemd}/bin/systemctl suspend"
      '';

    };

    # cgroups v1 is required for centos7 dockers
    # specialisation = {
    #   cgroup_v1.configuration = {
    #     boot.kernelParams = [
    #       "SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
    #       "systemd.unified_cgroup_hierarchy=0"
    #     ];
    #   };
    # };
  } // lib.optionalAttrs withHomeManager {

    home-manager.users."${config.swarselsystems.mainUser}" = {
      imports = [
        "${self}/modules/home/optional/work.nix"
      ];
    };
  };

}
