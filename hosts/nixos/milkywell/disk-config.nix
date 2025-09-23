# NOTE: ... is needed because dikso passes diskoFile
{ lib
, config
, ...
}:
let
  type = "btrfs";
  extraArgs = [ "-L" "nixos" "-f" ]; # force overwrite
  subvolumes = {
    "/root" = {
      mountpoint = "/";
      mountOptions = [
        "subvol=root"
        "compress=zstd"
        "noatime"
      ];
    };
    "/home" = lib.mkIf config.swarselsystems.isImpermanence {
      mountpoint = "/home";
      mountOptions = [
        "subvol=home"
        "compress=zstd"
        "noatime"
      ];
    };
    "/persist" = lib.mkIf config.swarselsystems.isImpermanence {
      mountpoint = "/persist";
      mountOptions = [
        "subvol=persist"
        "compress=zstd"
        "noatime"
      ];
    };
    "/log" = lib.mkIf config.swarselsystems.isImpermanence {
      mountpoint = "/var/log";
      mountOptions = [
        "subvol=log"
        "compress=zstd"
        "noatime"
      ];
    };
    "/nix" = {
      mountpoint = "/nix";
      mountOptions = [
        "subvol=nix"
        "compress=zstd"
        "noatime"
      ];
    };
    "/swap" = lib.mkIf config.swarselsystems.isSwap {
      mountpoint = "/.swapvol";
      swap.swapfile.size = config.swarselsystems.swapSize;
    };
  };
in
{
  disko.devices = {
    disk = {
      disk0 = {
        type = "disk";
        device = config.swarselsystems.rootDisk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            root = {
              size = "100%";
              content = {
                inherit type subvolumes extraArgs;
                postCreateHook = lib.mkIf config.swarselsystems.isImpermanence ''
                  MNTPOINT=$(mktemp -d)
                  mount "/dev/disk/by-label/nixos" "$MNTPOINT" -o subvolid=5
                  trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                  btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
                '';
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/persist".neededForBoot = lib.mkIf config.swarselsystems.isImpermanence true;
  fileSystems."/home".neededForBoot = lib.mkIf config.swarselsystems.isImpermanence true;
}
