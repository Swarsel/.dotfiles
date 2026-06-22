{ self, inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      _module.args.testsLib = rec {
        inputSources =
          let
            go =
              seen: queue:
              if queue == [ ] then
                seen
              else
                let
                  input = builtins.head queue;
                  rest = builtins.tail queue;
                  key = if input ? outPath then builtins.unsafeDiscardStringContext input.outPath else null;
                in
                if key == null || seen ? ${key} then
                  go seen rest
                else
                  go (seen // { ${key} = input; }) (rest ++ builtins.attrValues (input.inputs or { }));
          in
          builtins.attrValues (
            go { } (
              builtins.attrValues (
                builtins.removeAttrs self.inputs [
                  "vbc-nix"
                  "repoSecrets"
                ]
              )
            )
          );

        mkDemoTest =
          name: testArgs:
          if !(inputs.repoSecrets.isDemo or false) then
            pkgs.runCommand "${name}-needs-demo-overrides" { } ''
              echo "${name} must be built against the demo secrets so that the prebuilt system matches what swarsel-install builds inside the VM:" >&2
              echo "  nix build .#${name} --override-input repoSecrets path:./files/demo --override-input vbc-nix path:./files/stub --no-write-lock-file" >&2
              echo "or run 'just demo-test'." >&2
              exit 1
            ''
          else
            pkgs.testers.runNixOSTest (
              lib.recursiveUpdate {
                inherit name;

                globalTimeout = 4 * 3600;

                node = {
                  specialArgs = { inherit self; };
                  pkgsReadOnly = false;
                };

                defaults = {
                  documentation.enable = lib.mkDefault false;
                  nixpkgs.hostPlatform = system;
                };
              } testArgs
            );

        installerNode =
          {
            extraDependencies ? [ ],
            diskSize ? 32 * 1024,
          }:
          { lib, ... }: {
            imports = [
              inputs.home-manager.nixosModules.home-manager
              "${self}/install/installer-config.nix"
              "${inputs.nixpkgs}/nixos/modules/profiles/installation-device.nix"
              "${inputs.nixpkgs}/nixos/modules/profiles/base.nix"
              "${inputs.nixpkgs}/nixos/tests/common/auto-format-root-device.nix"
            ];

            virtualisation = {
              cores = 8;
              memorySize = 12288;
              diskImage = "./target.qcow2";
              inherit diskSize;
              emptyDiskImages = [ 20480 ];
              rootDevice = "/dev/vdb";
              fileSystems."/".autoFormat = true;
              useEFIBoot = true;
            };

            boot.supportedFilesystems = lib.mkOverride 40 [
              "btrfs"
              "vfat"
              "ext4"
            ];

            boot.kernel.sysctl = {
              "vm.dirty_bytes" = 268435456;
              "vm.dirty_background_bytes" = 67108864;
            };

            environment.systemPackages = [ pkgs.swarsel-install ];

            system.extraDependencies = [ self ] ++ extraDependencies ++ inputSources;

            nix.settings = {
              substituters = lib.mkForce [ ];
              connect-timeout = 1;
            };
          };

        targetNode =
          {
            toplevel,
            memorySize ? 4096,
            cores ? 2,
            quiet ? true,
          }:
          {
            virtualisation = {
              inherit cores memorySize;
              diskImage = "./target.qcow2";
              useDefaultFilesystems = false;
              directBoot.enable = false;
              fileSystems."/" = {
                device = "/dev/disk/by-label/unused";
                fsType = "btrfs";
              };
              qemu.options = [
                "-kernel ${toplevel}/kernel"
                "-initrd ${toplevel}/initrd"
                ''-append "$(cat ${toplevel}/kernel-params) init=${toplevel}/init console=ttyS0${lib.optionalString quiet " quiet"}"''
              ];
            };
          };

        prepareCloneSourceScript = machine: ''
          with subtest("Prepare local clone source"):
              ${machine}.succeed("cp -r ${self} /root/dotfiles-src && chmod -R u+w /root/dotfiles-src")
              ${machine}.succeed("git -C /root/dotfiles-src init -q -b main")
              ${machine}.succeed("git -C /root/dotfiles-src add -A")
              ${machine}.succeed("GIT_COMMITTER_DATE='@${
                toString (self.lastModified or 1)
              }' GIT_AUTHOR_DATE='@${
                toString (self.lastModified or 1)
              }' git -C /root/dotfiles-src -c commit.gpgsign=false -c user.email=demo@example.org -c user.name=demo commit -q -m demo")

          with subtest("Provide disk encryption passphrase"):
              ${machine}.succeed("echo demopass > /tmp/disko-password")
        '';

        runInstallScript = machine: ''
          with subtest("Run swarsel-install"):
              ${machine}.succeed("swarsel-install -n hotel -H -r /root/dotfiles-src >&2", timeout=7200)

          with subtest("Check installation results"):
              ${machine}.succeed("test -e /mnt/boot/EFI/systemd/systemd-bootx64.efi")
              ${machine}.succeed("test -e /mnt/nix/var/nix/profiles/system/init")
              ${machine}.succeed("test -d /mnt/persist/home/swarsel/.dotfiles")
        '';

        shutdownInstallerScript = machine: ''
          with subtest("Shut down installer"):
              ${machine}.succeed("umount -R /mnt")
              ${machine}.succeed("sync")
              ${machine}.shutdown()
        '';

        unlockBootScript =
          {
            machine,
            marker,
            title ? "Boot installed system, unlock disk and reach a shell",
          }:
          ''
            with subtest("${title}"):
                ${machine}.start()
                booted = False
                for _ in range(40):
                    ${machine}.send_console("demopass\n")
                    ${machine}.send_console("echo ${marker}-$(hostname)\n")
                    try:
                        ${machine}.wait_for_console_text("${marker}-hotel", timeout=15)
                        booted = True
                        break
                    except Exception:
                        pass
                assert booted, "installed system did not reach a shell after disk unlock"
          '';

        enablePasswordlessSudoScript =
          {
            machine,
            user ? "swarsel",
            password ? "setup",
          }:
          ''
            import time

            with subtest("Enable passwordless sudo for ${user}"):
                ok = False
                for _ in range(5):
                    ${machine}.send_console("echo '${user} ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/99-demo-test > /dev/null\n")
                    time.sleep(3)
                    ${machine}.send_console("${password}\n")
                    time.sleep(2)
                    ${machine}.send_console("sudo -n true && echo sudo-\"mark\"er-ok\n")
                    try:
                        ${machine}.wait_for_console_text("sudo-marker-ok", timeout=20)
                        ok = True
                        break
                    except Exception:
                        pass
                assert ok, "could not enable passwordless sudo for ${user}"
          '';

        unlockGraphicalBootScript =
          {
            machine,
            title ? "Boot full system, unlock disk and reach graphical.target",
            passphrase ? "demopass",
          }:
          ''
            import time

            with subtest("${title}"):
                ${machine}.start()
                for _ in range(20):
                    ${machine}.send_console("${passphrase}\n")
                    time.sleep(4)
                ${machine}.wait_for_console_text(r"Reached target.*[Gg]raphical", timeout=2400)
          '';

        consoleMarkerLoopScript =
          {
            machine,
            title,
            command,
            marker,
            tries ? 20,
            timeout ? 15,
            failure,
          }:
          ''
            with subtest("${title}"):
                ok = False
                for _ in range(${toString tries}):
                    ${machine}.send_console("${command} && echo ${marker}-\"mark\"er-ok\n")
                    try:
                        ${machine}.wait_for_console_text("${marker}-marker-ok", timeout=${toString timeout})
                        ok = True
                        break
                    except Exception:
                        pass
                assert ok, "${failure}"
          '';
      };
    };
}
