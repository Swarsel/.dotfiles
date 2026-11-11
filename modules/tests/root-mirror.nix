{ self, inputs, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    lib.optionalAttrs (lib.hasSuffix "-linux" system) {
      packages.root-mirror-test =
        let
          mirror = inputs.nixpkgs.lib.nixosSystem {
            modules = [
              inputs.disko.nixosModules.disko
              inputs.lanzaboote.nixosModules.lanzaboote
              self.modules.generic.options
              self.modules.nixos.disk-encrypt
              self.modules.nixos.impermanence
              self.modules.nixos.disk-mirrored-root
              "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
              (
                { config, pkgs, ... }:
                {
                  swarselsystems = {
                    isBtrfs = true;
                    isCrypted = true;
                    isImpermanence = true;
                    rootDisk = "/dev/disk/by-id/virtio-mirror-a";
                    rootMirrorDisk = "/dev/disk/by-id/virtio-mirror-b";
                  };
                  services.getty.autologinUser = "root";
                  boot = {
                    initrd.systemd = {
                      services.root-mirror-degraded.serviceConfig.StandardError = "journal+console";
                      contents."/etc/ssh/authorized_keys.d/root".source = lib.mkForce (
                        pkgs.runCommand "root-mirror-test-authorized-keys" { } ''
                          echo "command=\"${config.swarselsystems.initrdSshCommand}\" $(cat ${testKey}/key.pub)" > $out
                        ''
                      );
                      emergencyAccess = true;
                      network = {
                        enable = true;
                        networks."10-test" = {
                          address = [ "192.168.1.200/24" ];
                          matchConfig.Name = "en* eth*";
                        };
                      };
                    };
                    loader.grub.enable = false;
                  };
                  networking.hostName = "mirror";
                  nixpkgs = {
                    hostPlatform = system;
                    overlays = [ self.overlays.additions ];
                  };
                  system.stateVersion = "26.05";
                }
              )
            ];
            specialArgs = {
              inherit self inputs;
              inherit (self.outputs) lib;
              inherit (self.outputs.swarselsystemsLib) root;
              minimal = true;
            };
          };
          inherit
            (import "${inputs.nixpkgs}/nixos/lib/qemu-common.nix" {
              inherit lib;
              inherit (pkgs) stdenv;
            })
            qemuSerialDevice
            ;
          testKey = pkgs.runCommand "root-mirror-test-key" { nativeBuildInputs = [ pkgs.openssh ]; } ''
            mkdir $out
            ssh-keygen -q -t ed25519 -N "" -C root-mirror-test -f $out/key
          '';
          normal = mirror.config.system.build.toplevel;
          mkTarget = disks: {
            virtualisation = {
              directBoot.enable = false;
              diskImage = null;
              fileSystems."/" = {
                device = "/dev/disk/by-label/unused";
                fsType = "btrfs";
              };
              memorySize = 2048;
              qemu = {
                options = [
                  "-kernel ${normal}/kernel"
                  "-initrd ${normal}/initrd"
                  ''-append "$(cat ${normal}/kernel-params) init=${normal}/init console=${qemuSerialDevice}"''
                ];
                drives = map (disk: {
                  deviceExtraOpts.serial = "mirror-${disk}";
                  file = "$(pwd)/disk-${disk}.qcow2";
                  name = "disk-${disk}";
                }) disks;
                networkingOptions = lib.mkForce [ ];
              };
              useDefaultFilesystems = false;
              useEFIBoot = true;
            };
          };
        in
        pkgs.testers.runNixOSTest {
          name = "root-mirror-test";
          testScript = ''
            import shutil
            from datetime import timedelta
            from test_driver.errors import RequestedAssertionFailed

            with subtest("install"):
                installer.start()
                installer.wait_for_unit("multi-user.target")
                installer.succeed("echo mirrorpass > /tmp/disko-password")
                installer.succeed("${mirror.config.system.build.formatMount}/bin/disko-format-mount >&2", timeout=timedelta(minutes=15))
                installer.succeed("btrfs filesystem df /mnt | grep -q 'Data, RAID1'")
                installer.succeed("nixos-install --no-root-passwd --no-bootloader --no-channel-copy --system ${normal} >&2", timeout=timedelta(minutes=30))
                installer.succeed("umount -R /mnt && cryptsetup close cryptroot && cryptsetup close cryptroot-mirror && sync")
                installer.shutdown()
                for index, disk in enumerate("ab"):
                    (installer.state_dir / f"empty{index}.qcow2").rename(installer.state_dir / f"disk-{disk}.qcow2")

            def boot(machine):
                machine.state_dir = installer.state_dir
                machine.start()
                for _ in range(40):
                    machine.send_console("mirrorpass\n")
                    try:
                        machine.wait_for_console_text("root@mirror:~", timeout=timedelta(seconds=15))
                        return
                    except RequestedAssertionFailed:
                        continue
                raise RequestedAssertionFailed(f"{machine.name} did not reach a shell")

            def check(machine, command):
                machine.send_console(f"{command} && printf 'check-%s\\n' ok\n")
                machine.wait_for_console_text("check-ok", timeout=timedelta(minutes=2))

            def poweroff(machine):
                machine.send_console("poweroff\n")
                machine.wait_for_shutdown()

            def assert_degraded_flag(machine):
                machine.wait_for_console_text("reboot: Restarting system", timeout=timedelta(minutes=3))
                machine.wait_for_shutdown()
                flags = [var.data for var in machine.read_efi_vars() if var.name == "SwarselDegraded"]
                assert flags == [b"\x01"], f"{machine.name} has SwarselDegraded {flags!r}"

            def degraded_checks(machine):
                check(machine, "btrfs filesystem show / | grep -qi missing")
                check(machine, "test ! -e /sys/firmware/efi/efivars/SwarselDegraded-*")
                check(machine, "grep -q kept /persist/marker")
                check(machine, "test ! -e /wiped")

            with subtest("both disks"):
                boot(both)
                check(both, "test \"$(btrfs filesystem show / | grep -c devid)\" = 2 && ! btrfs filesystem show / | grep -qi missing")
                check(both, "btrfs filesystem df / | grep -q 'Data, RAID1' && btrfs filesystem df / | grep -q 'Metadata, RAID1'")
                check(both, "echo kept > /persist/marker && touch /wiped && sync")
                both.send_console("swarsel-degraded\n")
                assert_degraded_flag(both)

            with subtest("flagged boot with disk b"):
                shutil.copy(both.efi_vars_path, onlyB.efi_vars_path)
                boot(onlyB)
                degraded_checks(onlyB)
                poweroff(onlyB)

            with subtest("unflagged boot with disk a stops in initrd"):
                hungA.state_dir = installer.state_dir
                hungA.start()
                hungA.wait_for_console_text("passphrase", timeout=timedelta(minutes=5))
                hungA.send_console("mirrorpass\n")
                hungA.wait_for_console_text("Press Enter for system maintenance", timeout=timedelta(minutes=5))
                client.start()
                client.wait_until_succeeds("nc -z 192.168.1.200 2222", timeout=timedelta(minutes=5))
                client.execute("ssh -p 2222 -i /etc/mirror-key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.200 degraded")
                assert_degraded_flag(hungA)

            with subtest("flagged boot with disk a"):
                boot(hungA)
                degraded_checks(hungA)
                poweroff(hungA)
          '';
          nodes = {
            both = mkTarget [
              "a"
              "b"
            ];
            client.environment = {
              etc.mirror-key = {
                mode = "0600";
                source = "${testKey}/key";
              };
              systemPackages = [ pkgs.netcat ];
            };
            hungA = mkTarget [ "a" ];
            installer = {
              boot.supportedFilesystems = [ "btrfs" ];
              environment.systemPackages = [ pkgs.cryptsetup ];
              nix.settings.substituters = lib.mkForce [ ];
              virtualisation = {
                additionalPaths = [
                  normal
                  mirror.config.system.build.formatMount
                ];
                emptyDiskImages = [
                  {
                    driveConfig.deviceExtraOpts.serial = "mirror-a";
                    size = 4096;
                  }
                  {
                    driveConfig.deviceExtraOpts.serial = "mirror-b";
                    size = 4096;
                  }
                ];
                memorySize = 4096;
              };
            };
            onlyB = mkTarget [ "b" ];
          };
        };
    };
}
