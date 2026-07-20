{ config, lib, ... }:
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
  disko.devices.disk.disk0 = {
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
        luks = lib.mkIf config.swarselsystems.isCrypted {
          content = {
            content = {
              inherit extraArgs subvolumes type;
              postCreateHook = lib.mkIf config.swarselsystems.isImpermanence ''
                MNTPOINT=$(mktemp -d)
                mount "/dev/mapper/cryptroot" "$MNTPOINT" -o subvolid=5
                trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
              '';
            };
            name = "cryptroot";
            passwordFile = "/tmp/disko-password"; # this is populated by bootstrap.sh
            settings = {
              allowDiscards = true;
              # https://github.com/hmajid2301/dotfiles/blob/a0b511c79b11d9b4afe2a5e2b7eedb2af23e288f/systems/x86_64-linux/framework/disks.nix#L36
              crypttabExtraOpts = [
                "fido2-device=auto"
                "token-timeout=10"
              ];
            };
            type = "luks";
          };
          size = "100%";
        };
        root = lib.mkIf (!config.swarselsystems.isCrypted) {
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

  fileSystems = {
    "/home".neededForBoot = lib.mkIf config.swarselsystems.isImpermanence true;
    "/persist".neededForBoot = lib.mkIf config.swarselsystems.isImpermanence true;
  };
}
