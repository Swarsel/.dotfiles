# NOTE: ... is needed because dikso passes diskoFile
{
  config,
  lib,
  ...
}:
let
  type = "btrfs";
  extraArgs = [
    "-L"
    "nixos"
    "-f"
  ]; # force overwrite
  subvolumes = {
    "/home" = lib.mkIf config.swarselsystems.isImpermanence {
      mountOptions = [
        "subvol=home"
        "compress=zstd"
        "noatime"
      ];
      mountpoint = "/home";
    };
    "/log" = lib.mkIf config.swarselsystems.isImpermanence {
      mountOptions = [
        "subvol=log"
        "compress=zstd"
        "noatime"
      ];
      mountpoint = "/var/log";
    };
    "/nix" = {
      mountOptions = [
        "subvol=nix"
        "compress=zstd"
        "noatime"
      ];
      mountpoint = "/nix";
    };
    "/persist" = lib.mkIf config.swarselsystems.isImpermanence {
      mountOptions = [
        "subvol=persist"
        "compress=zstd"
        "noatime"
      ];
      mountpoint = "/persist";
    };
    "/root" = {
      mountOptions = [
        "subvol=root"
        "compress=zstd"
        "noatime"
      ];
      mountpoint = "/";
    };
    "/swap" = lib.mkIf config.swarselsystems.isSwap {
      mountpoint = "/.swapvol";
      swap.swapfile.size = config.swarselsystems.swapSize;
    };
  };
in
{
  disko.devices.disk = {
    disk0 = {
      content = {
        partitions = {
          ESP = {
            content = {
              format = "vfat";
              mountOptions = [ "defaults" ];
              mountpoint = "/boot";
              type = "filesystem";
            };
            name = "ESP";
            priority = 1;
            size = "512M";
            type = "EF00";
          };
          root = {
            content = {
              inherit extraArgs subvolumes type;
              postCreateHook = lib.mkIf config.swarselsystems.isImpermanence ''
                MNTPOINT=$(mktemp -d)
                mount "/dev/disk/by-label/nixos" "$MNTPOINT" -o subvolid=5
                trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
              '';
            };
            size = "100%";
          };
        };
        type = "gpt";
      };
      device = config.swarselsystems.rootDisk;
      type = "disk";
    };
    disk1 = {
      content = {
        partitions.sync = {
          content = {
            extraArgs = [
              "-L"
              "sync"
              "-f"
            ]; # force overwrite
            subvolumes."/sync" = {
              mountOptions = [
                "subvol=root"
                "compress=zstd"
                "noatime"
              ];
              mountpoint = "/sync";
            };
            type = "btrfs";
          };
          size = "100%";
        };
        type = "gpt";
      };
      device = "/dev/sdb";
      type = "disk";
    };
  };

  fileSystems = {
    "/home".neededForBoot = lib.mkIf config.swarselsystems.isImpermanence true;
    "/persist".neededForBoot = lib.mkIf config.swarselsystems.isImpermanence true;
  };
}
