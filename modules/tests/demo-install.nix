{ self, ... }:
{
  perSystem = { lib, system, testsLib, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.demo-install-test =
        let
          hotel = self.nixosConfigurationsMinimal.hotel;
          toplevel = hotel.config.system.build.toplevel;
        in
        testsLib.mkDemoTest "demo-install-test" {
          nodes = {
            installer = testsLib.installerNode {
              extraDependencies = [
                toplevel
                hotel.config.system.build.destroyFormatMount
              ];
            };

            target = testsLib.targetNode { inherit toplevel; };
          };

          testScript = ''
            installer.start()
            installer.wait_for_unit("multi-user.target")

            ${testsLib.prepareCloneSourceScript "installer"}

            ${testsLib.runInstallScript "installer"}

            ${testsLib.shutdownInstallerScript "installer"}

            target.state_dir = installer.state_dir

            ${testsLib.unlockBootScript { machine = "target"; marker = "boot-marker"; }}

            target.crash()
          '';
        };
    };
}
