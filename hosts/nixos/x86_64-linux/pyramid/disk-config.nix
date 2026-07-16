{
  disko.devices = {
    disk = {
      nvme0n1 = {
        content = {
          partitions = {
            ESP = {
              content = {
                format = "vfat";
                mountOptions = [
                  "defaults"
                ];
                mountpoint = "/boot";
                type = "filesystem";
              };
              label = "boot";
              name = "ESP";
              size = "512M";
              type = "EF00";
            };
            luks = {
              content = {
                content = {
                  extraArgs = [
                    "-L"
                    "nixos"
                    "-f"
                  ];
                  subvolumes = {
                    "/home" = {
                      mountOptions = [
                        "subvol=home"
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/home";
                    };
                    "/log" = {
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
                    "/persist" = {
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
                    "/swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "64G";
                    };
                  };
                  type = "btrfs";
                };
                extraOpenArgs = [
                  "--allow-discards"
                  "--perf-no_read_workqueue"
                  "--perf-no_write_workqueue"
                ];
                name = "cryptroot";
                # https://0pointer.net/blog/unlocking-luks2-volumes-with-tpm2-fido2-pkcs11-security-hardware-on-systemd-248.html
                settings = {
                  crypttabExtraOpts = [
                    "fido2-device=auto"
                    "token-timeout=10"
                  ];
                };
                type = "luks";
              };
              label = "luks";
              size = "100%";
            };
          };
          type = "gpt";
        };
        device = "/dev/nvme0n1";
        type = "disk";
      };
    };
  };

  fileSystems = {
    "/".neededForBoot = true; # this is ok because this is not a impermanence host
    "/home".neededForBoot = true;
    "/persist".neededForBoot = true;
    "/var/log".neededForBoot = true;
  };
}
