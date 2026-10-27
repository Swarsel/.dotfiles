{ self, inputs, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.root-mirror-test =
        let
          mirror = inputs.nixpkgs.lib.nixosSystem {
            modules = [
              inputs.disko.nixosModules.disko
              inputs.lanzaboote.nixosModules.lanzaboote
              self.modules.generic.options
              self.modules.nixos.disk-encrypt
              self.modules.nixos.impermanence
              self.modules.nixos.disk-setup
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
          testKey = pkgs.runCommand "root-mirror-test-key" { nativeBuildInputs = [ pkgs.openssh ]; } ''
            mkdir $out
            ssh-keygen -q -t ed25519 -N "" -C root-mirror-test -f $out/key
          '';
          normal = mirror.config.system.build.toplevel;
          mkTarget = toplevel: disks: {
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
                  "-kernel ${toplevel}/kernel"
                  "-initrd ${toplevel}/initrd"
                  ''-append "$(cat ${toplevel}/kernel-params) init=${toplevel}/init console=ttyS0"''
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
            import os
            import shutil

            installer.start()
            installer.wait_for_unit("multi-user.target")

            with subtest("Format both disks as LUKS-backed btrfs RAID1 and install"):
                installer.succeed("echo mirrorpass > /tmp/disko-password")
                installer.succeed("${mirror.config.system.build.formatMount}/bin/disko-format-mount >&2", timeout=900)
                installer.succeed("btrfs filesystem df /mnt | grep -q 'Data, RAID1'")
                installer.succeed("nixos-install --no-root-passwd --no-bootloader --no-channel-copy --system ${normal} >&2", timeout=1800)
                installer.succeed("umount -R /mnt && cryptsetup close cryptroot && cryptsetup close cryptroot-mirror && sync")

            installer.shutdown()
            os.rename(os.path.join(installer.state_dir, "empty0.qcow2"), os.path.join(installer.state_dir, "disk-a.qcow2"))
            os.rename(os.path.join(installer.state_dir, "empty1.qcow2"), os.path.join(installer.state_dir, "disk-b.qcow2"))

            checks = 0

            def check(machine, title, command):
                global checks
                checks += 1
                with subtest(title):
                    machine.send_console(f"{command} && echo check-\"ok\"-{checks}\n")
                    machine.wait_for_console_text(f"check-ok-{checks}", timeout=120)

            def boot(machine, title):
                with subtest(title):
                    machine.state_dir = installer.state_dir
                    machine.start()
                    for _ in range(40):
                        machine.send_console("mirrorpass\n")
                        machine.send_console("echo booted-$(hostname)\n")
                        try:
                            machine.wait_for_console_text("booted-mirror", timeout=15)
                            return
                        except Exception:
                            pass
                    raise Exception(f"{machine.name} did not reach a shell")

            def poweroff(machine):
                machine.send_console("poweroff\n")
                machine.wait_for_shutdown()

            def assert_degraded_flag(machine):
                machine.wait_for_console_text("reboot: Restarting system", timeout=180)
                machine.wait_for_shutdown()
                flag = next(
                    (v.data for vendor in (machine.efi_vars.read_content() or {}).values() for name, v in vendor.items() if name == "SwarselDegraded"),
                    None,
                )
                assert flag == b"\x01", f"{machine.name} set SwarselDegraded to {flag!r}"

            def degraded_checks(machine):
                check(machine, f"{machine.name}: btrfs reports the missing device", "btrfs filesystem show / | grep -qi missing")
                check(machine, f"{machine.name}: the degraded flag was consumed", "test ! -e /sys/firmware/efi/efivars/SwarselDegraded-*")
                check(machine, f"{machine.name}: persisted data survived", "grep -q kept /persist/marker")
                check(machine, f"{machine.name}: impermanence rollback ran", "test ! -e /wiped")

            boot(both, "Normal boot with both disks")
            check(both, "Root spans both devices", "test \"$(btrfs filesystem show / | grep -c devid)\" = 2 && ! btrfs filesystem show / | grep -qi missing")
            check(both, "Data and metadata are RAID1", "btrfs filesystem df / | grep -q 'Data, RAID1' && btrfs filesystem df / | grep -q 'Metadata, RAID1'")
            check(both, "Persist a marker and leave a file on the ephemeral root", "echo kept > /persist/marker && touch /wiped && sync")
            with subtest("swarsel-degraded sets the degraded flag and reboots"):
                both.send_console("swarsel-degraded\n")
                assert_degraded_flag(both)

            shutil.copy(both.efi_vars_path, onlyB.efi_vars_path)
            boot(onlyB, "Flagged boot with only disk B comes up degraded")
            degraded_checks(onlyB)
            poweroff(onlyB)

            with subtest("Without the flag, a missing disk stops the boot instead of mounting degraded"):
                hungA.state_dir = installer.state_dir
                hungA.start()
                hungA.wait_for_console_text("passphrase", timeout=300)
                hungA.send_console("mirrorpass\n")
                hungA.wait_for_console_text("Press Enter for system maintenance", timeout=300)

            with subtest("The stuck boot sets the degraded flag over initrd SSH"):
                client.start()
                client.wait_until_succeeds("nc -z 192.168.1.200 2222", timeout=300)
                client.execute("ssh -p 2222 -i /etc/mirror-key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.200 degraded")
                assert_degraded_flag(hungA)

            boot(hungA, "Flagged boot with only disk A comes up degraded")
            degraded_checks(hungA)
            poweroff(hungA)
          '';
          nodes = {
            both = mkTarget normal [
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
            hungA = mkTarget normal [ "a" ];
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
            onlyB = mkTarget normal [ "b" ];
          };
        };
    };
}
