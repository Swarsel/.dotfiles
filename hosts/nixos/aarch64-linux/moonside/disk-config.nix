{
  disko.devices.disk.disk1 = {
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
}
