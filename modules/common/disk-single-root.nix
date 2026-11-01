{
  flake.modules.nixos.disk-single-root =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.swarselsystems)
        isCloud
        isCrypted
        isImpermanence
        isSwap
        rootDisk
        swapSize
        ;
      mountOptions = subvol: [
        "subvol=${subvol}"
        "compress=zstd"
        "noatime"
      ];
      btrfs = device: {
        extraArgs = [
          "-L"
          "nixos"
          "-f"
        ];
        postCreateHook = lib.mkIf isImpermanence ''
          MNTPOINT=$(mktemp -d)
          mount "${device}" "$MNTPOINT" -o subvolid=5
          trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
          btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
        '';
        subvolumes = {
          "/home" = lib.mkIf isImpermanence {
            mountOptions = mountOptions "home";
            mountpoint = "/home";
          };
          "/log" = lib.mkIf isImpermanence {
            mountOptions = mountOptions "log";
            mountpoint = "/var/log";
          };
          "/nix" = {
            mountOptions = mountOptions "nix";
            mountpoint = "/nix";
          };
          "/persist" = lib.mkIf isImpermanence {
            mountOptions = mountOptions "persist";
            mountpoint = "/persist";
          };
          "/root" = {
            mountOptions = mountOptions "root";
            mountpoint = "/";
          };
          "/swap" = lib.mkIf isSwap {
            mountpoint = "/.swapvol";
            swap.swapfile.size = swapSize;
          };
        };
        type = "btrfs";
      };
    in
    {
      disko = {
        devices.disk.disk0 = {
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
              luks = lib.mkIf isCrypted {
                content = {
                  content = btrfs "/dev/mapper/cryptroot";
                  name = "cryptroot";
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
              root = lib.mkIf (!isCrypted) {
                content = btrfs "/dev/disk/by-label/nixos";
                size = "100%";
              };
            };
            type = "gpt";
          };
          device = rootDisk;
          type = "disk";
        };
        imageBuilder.extraDependencies = lib.mkIf (isCloud && isCrypted) [ pkgs.kmod ];
      };

      fileSystems = {
        "/home".neededForBoot = lib.mkIf isImpermanence true;
        "/persist".neededForBoot = lib.mkIf isImpermanence true;
      };
    };
}
