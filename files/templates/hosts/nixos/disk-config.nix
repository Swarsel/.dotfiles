{ lib, pkgs, config, rootDisk, ... }:
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
            root = lib.mkIf (!config.swarselsystems.isCrypted) {
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
            luks = lib.mkIf config.swarselsystems.isCrypted {
              size = "100%";
              content = {
                type = "luks";
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
                content = {
                  inherit type subvolumes extraArgs;
                  postCreateHook = lib.mkIf config.swarselsystems.isImpermanence ''
                    MNTPOINT=$(mktemp -d)
                    mount "/dev/mapper/cryptroot" "$MNTPOINT" -o subvolid=5
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
  };

  fileSystems."/persist".neededForBoot = lib.mkIf config.swarselsystems.isImpermanence true;
  fileSystems."/home".neededForBoot = lib.mkIf config.swarselsystems.isImpermanence true;

  environment.systemPackages = [
    pkgs.yubikey-manager
  ];
}
