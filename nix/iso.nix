{ self, inputs, ... }:
{
  perSystem = { pkgs, system, ... }:
    {
      packages = {
        # nix build --print-out-paths --no-link .#live-iso
        live-iso = inputs.nixos-generators.nixosGenerate {
          inherit pkgs;
          specialArgs = { inherit self; };
          modules = [
            inputs.home-manager.nixosModules.home-manager
            "${self}/install/installer-config.nix"
          ];
          format =
            {
              x86_64-linux = "install-iso";
              aarch64-linux = "sd-aarch64-installer";
            }.${system};
        };

        # nix build --print-out-paths --no-link .#pnap-kexec --system <system>
        swarsel-kexec = (inputs.smallpkgs.legacyPackages.${system}.nixos [
          {
            imports = [ "${self}/install/kexec.nix" ];
            _file = __curPos.file;
            system.kexec-installer.name = "swarsel-kexec";
          }
          inputs.nixos-images.nixosModules.kexec-installer
        ]).config.system.build.kexecInstallerTarball;

      };
    };
}
