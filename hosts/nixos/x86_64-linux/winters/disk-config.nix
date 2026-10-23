{ config, lib, ... }:
let
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
              mountOptions = [ "defaults" ] ++ lib.optional (espMountpoint != "/boot") "nofail";
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
    ];
  };
in
{
  boot.lanzaboote.extraEfiSysMountPoints = [ "/boot-mirror" ];

  disko.devices.disk = {
    disk0 = mkDisk {
      content = null;
      cryptName = "cryptroot";
      device = config.swarselsystems.rootDisk;
      espMountpoint = "/boot";
    };
    disk1 = mkDisk {
      content = {
        extraArgs = [
          "-L"
          "nixos"
          "-f"
          "-d"
          "raid1"
          "-m"
          "raid1"
          "/dev/mapper/cryptroot"
        ];
        postCreateHook = ''
          MNTPOINT=$(mktemp -d)
          mount "/dev/mapper/cryptroot-mirror" "$MNTPOINT" -o subvolid=5
          trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
          btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
        '';
        subvolumes = {
          "/home" = mkSubvolume "home" "/home";
          "/log" = mkSubvolume "log" "/var/log";
          "/nix" = mkSubvolume "nix" "/nix";
          "/persist" = mkSubvolume "persist" "/persist";
          "/root" = mkSubvolume "root" "/";
        };
        type = "btrfs";
      };
      cryptName = "cryptroot-mirror";
      device = "/dev/disk/by-id/ata-C300-CTFDDAC064MAG_00000000104302FE494D";
      espMountpoint = "/boot-mirror";
    };
  };

  fileSystems = {
    "/home".neededForBoot = true;
    "/persist".neededForBoot = true;
  };
}
