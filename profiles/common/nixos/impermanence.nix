{ config, lib, ... }:
let
  mkIfElse = p: yes: no: if p then yes else no;
  mkIfElseList = p: yes: no: lib.mkMerge [
    (lib.mkIf p yes)
    (lib.mkIf (!p) no)
  ];
  mapperTarget = mkIfElse config.swarselsystems.isCrypted "/dev/mapper/cryptroot" "/dev/disk/by-label/nixos";
in

{

  security.sudo.extraConfig = lib.mkIf config.swarselsystems.impermanence ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';

  # This script does the actual wipe of the system
  # So if it doesn't run, the btrfs system effectively acts like a normal system
  # Taken from https://github.com/NotAShelf/nyx/blob/2a8273ed3f11a4b4ca027a68405d9eb35eba567b/modules/core/common/system/impermanence/default.nix

  boot.initrd.systemd.enable = true;

  boot.initrd.systemd.services.rollback = lib.mkIf config.swarselsystems.impermanence {
    description = "Rollback BTRFS root subvolume to a pristine state";
    wantedBy = [ "initrd.target" ];
    # make sure it's done after encryption
    # i.e. LUKS/TPM process
    after = mkIfElseList config.swarselsystems.isCrypted [ "systemd-cryptsetup@cryptroot.service" ] [ "dev-disk-by\\x2dlabel-nixos.device" ];
    requires = lib.mkIf (!config.swarselsystems.isCrypted) [ "dev-disk-by\\x2dlabel-nixos.device" ];
    # mount the root fs before clearing
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt

      # We first mount the btrfs root to /mnt
      # so we can manipulate btrfs subvolumes.
      mount -o subvolid=5 -t btrfs ${mapperTarget} /mnt
      btrfs subvolume list -o /mnt/root

      # While we're tempted to just delete /root and create
      # a new snapshot from /root-blank, /root is already
      # populated at this point with a number of subvolumes,
      # which makes `btrfs subvolume delete` fail.
      # So, we remove them first.
      #
      # /root contains subvolumes:
      # - /root/var/lib/portables
      # - /root/var/lib/machines

      btrfs subvolume list -o /mnt/root |
      cut -f9 -d' ' |
      while read subvolume; do
        echo "deleting /$subvolume subvolume..."
        btrfs subvolume delete "/mnt/$subvolume"
      done &&
      echo "deleting /root subvolume..." &&
      btrfs subvolume delete /mnt/root

      echo "restoring blank /root subvolume..."
      btrfs subvolume snapshot /mnt/root-blank /mnt/root

      # Once we're done rolling back to a blank snapshot,
      # we can unmount /mnt and continue on the boot process.
      umount /mnt
    '';
  };


  environment.persistence."/persist" = lib.mkIf config.swarselsystems.impermanence {
    hideMounts = true;
    directories =
      [
        "/.cache/nix"
        "/srv"
        "/etc/nixos"
        "/etc/nix"
        "/etc/NetworkManager/system-connections"
        "/etc/secureboot"
        "/var/db/sudo"
        "/var/cache"
        "/var/lib"
      ];

    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

}
