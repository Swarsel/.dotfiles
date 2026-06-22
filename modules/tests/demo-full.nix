{ self, ... }:
{
  perSystem =
    {
      lib,
      system,
      pkgs,
      testsLib,
      ...
    }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.demo-full-test =
        let
          hotelMinimal = self.nixosConfigurationsMinimal.hotel;
          minimalToplevel = hotelMinimal.config.system.build.toplevel;
          fullToplevel = self.nixosConfigurations.hotel.config.system.build.toplevel;
          rebuildCommand = "${pkgs.swarsel-rebuild}/bin/swarsel-rebuild -n hotel -H -r /persist/home/swarsel/.dotfiles";
        in
        testsLib.mkDemoTest "demo-full-test" {
          globalTimeout = 8 * 3600;

          nodes = {
            installer = testsLib.installerNode {
              diskSize = 96 * 1024;
              extraDependencies = [
                minimalToplevel
                hotelMinimal.config.system.build.destroyFormatMount
                fullToplevel
                pkgs.swarsel-rebuild
              ];
            };

            target = testsLib.targetNode {
              toplevel = minimalToplevel;
              memorySize = 10240;
              cores = 4;
            };

            full = testsLib.targetNode {
              toplevel = fullToplevel;
              memorySize = 8192;
              cores = 4;
              quiet = false;
            };
          };

          testScript = ''
            installer.start()
            installer.wait_for_unit("multi-user.target")

            ${testsLib.prepareCloneSourceScript "installer"}

            ${testsLib.runInstallScript "installer"}

            with subtest("Copy full system closure to the target disk"):
                installer.succeed("mount -o remount,commit=5 /mnt")
                installer.succeed("set -e; for p in ${fullToplevel} ${pkgs.swarsel-rebuild} ${toString testsLib.inputSources}; do nix copy --no-check-sigs --to /mnt \"$p\"; sync /mnt; echo 3 > /proc/sys/vm/drop_caches; done >&2", timeout=14400)

            ${testsLib.shutdownInstallerScript "installer"}

            target.state_dir = installer.state_dir

            ${testsLib.unlockBootScript {
              machine = "target";
              marker = "boot-minimal";
              title = "Boot minimal system and unlock disk";
            }}

            ${testsLib.enablePasswordlessSudoScript { machine = "target"; }}

            with subtest("Rebuild to the full configuration"):
                target.send_console("${rebuildCommand} > /tmp/rebuild.log 2>&1 && echo rebuild-\"mark\"er-ok || echo rebuild-\"mark\"er-fail\n")
                target.wait_for_console_text("rebuild-marker-(ok|fail)", timeout=14400)
                target.send_console("tail -n 25 /tmp/rebuild.log\n")
                time.sleep(30)

            ${testsLib.consoleMarkerLoopScript {
              machine = "target";
              title = "Check that a second system generation exists";
              command = "test -e /nix/var/nix/profiles/system-2-link";
              marker = "gen";
              tries = 3;
              failure = "nixos-rebuild did not create a second system generation";
            }}

            target.crash()

            full.state_dir = installer.state_dir

            ${testsLib.unlockGraphicalBootScript { machine = "full"; }}

            full.crash()
          '';
        };
    };
}
