{
  flake.modules.nixos.disk-setup =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      label = "nixos";
      rootLuks = "cryptroot";
      mirrorLuks = "cryptroot-mirror";
      initrdSshCommand = pkgs.writeShellScript "initrd-ssh-command" ''
        if [ "''${SSH_ORIGINAL_COMMAND:-}" = degraded ]; then
          exec ${lib.getExe pkgs.swarsel-degraded}
        fi
        exec /bin/systemctl default
      '';
      degradedFlag = "/run/root-mirror-degraded";
      efiVariable = "/sys/firmware/efi/efivars/${pkgs.swarsel-degraded.efiVariable}";
      mkDisk =
        {
          content,
          cryptName,
          device,
          espMountpoint,
        }:
        {
          inherit device;
          content = {
            partitions = {
              ESP = {
                content = {
                  format = "vfat";
                  mountOptions = [
                    "defaults"
                    "nofail"
                  ];
                  mountpoint = espMountpoint;
                  type = "filesystem";
                };
                name = "ESP";
                priority = 1;
                size = "512M";
                type = "EF00";
              };
              luks = {
                content = {
                  inherit content;
                  name = cryptName;
                  passwordFile = "/tmp/disko-password";
                  settings = {
                    allowDiscards = true;
                    crypttabExtraOpts = [
                      "fido2-device=auto"
                      "token-timeout=10"
                      "nofail"
                      "x-systemd.device-timeout=30s"
                    ];
                  };
                  type = "luks";
                };
                size = "100%";
              };
            };
            type = "gpt";
          };
          type = "disk";
        };
      mkSubvolume = name: mountpoint: {
        inherit mountpoint;
        mountOptions = [
          "subvol=${name}"
          "compress=zstd"
          "noatime"
          "degraded"
        ];
      };
      subvolumes = {
        "/home" = mkSubvolume "home" "/home";
        "/log" = mkSubvolume "log" "/var/log";
        "/nix" = mkSubvolume "nix" "/nix";
        "/persist" = mkSubvolume "persist" "/persist";
        "/root" = mkSubvolume "root" "/";
      };
    in
    {
      options.swarselsystems.rootMirrorDisk = lib.mkOption {
        type = lib.types.str;
      };
      config = {
        swarselsystems.initrdSshCommand = "${initrdSshCommand}";
        boot = {
          initrd = {
            services.udev.rules = ''TEST=="${degradedFlag}", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="btrfs", ENV{ID_FS_LABEL}=="${label}", ENV{SYSTEMD_READY}="1"'';
            systemd = {
              services = {
                root-mirror-degraded = {
                  before = [ "cryptsetup-pre.target" ];
                  script = ''
                    ${lib.getExe' pkgs.e2fsprogs "chattr"} -i ${efiVariable}
                    rm ${efiVariable}
                    touch ${degradedFlag}
                  '';
                  serviceConfig.Type = "oneshot";
                  unitConfig = {
                    ConditionPathExists = efiVariable;
                    DefaultDependencies = "no";
                  };
                  wantedBy = [ "initrd.target" ];
                  wants = [ "cryptsetup-pre.target" ];
                };
                root-mirror-scan = {
                  after = map (name: "systemd-cryptsetup@${utils.escapeSystemdPath name}.service") [
                    rootLuks
                    mirrorLuks
                  ];
                  before = [
                    "rollback.service"
                    "sysroot.mount"
                  ];
                  script = ''
                    udevadm settle
                    btrfs device scan
                  '';
                  serviceConfig.Type = "oneshot";
                  unitConfig = {
                    ConditionPathExists = degradedFlag;
                    DefaultDependencies = "no";
                  };
                  wantedBy = [ "initrd.target" ];
                };
              };
              storePaths = [
                initrdSshCommand
                (lib.getExe pkgs.swarsel-degraded)
                (lib.getExe' pkgs.e2fsprogs "chattr")
              ];
            };
          };
          lanzaboote.extraEfiSysMountPoints = [ "/boot-mirror" ];
        };
        disko.devices.disk = {
          disk0 = mkDisk {
            content = null;
            cryptName = rootLuks;
            device = config.swarselsystems.rootDisk;
            espMountpoint = "/boot";
          };
          disk1 = mkDisk {
            content = {
              inherit subvolumes;
              extraArgs = [
                "-L"
                label
                "-f"
                "-d"
                "raid1"
                "-m"
                "raid1"
                "/dev/mapper/${rootLuks}"
              ];
              postCreateHook = ''
                MNTPOINT=$(mktemp -d)
                mount "/dev/mapper/${mirrorLuks}" "$MNTPOINT" -o subvolid=5
                trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
              '';
              type = "btrfs";
            };
            cryptName = mirrorLuks;
            device = config.swarselsystems.rootMirrorDisk;
            espMountpoint = "/boot-mirror";
          };
        };
        environment.systemPackages = [ pkgs.swarsel-degraded ];
        fileSystems = lib.mkMerge [
          (lib.genAttrs (lib.mapAttrsToList (_: subvolume: subvolume.mountpoint) subvolumes) (_: {
            device = lib.mkForce "/dev/disk/by-label/${label}";
          }))
          {
            "/home".neededForBoot = true;
            "/persist".neededForBoot = true;
          }
        ];
      };
    };
}
