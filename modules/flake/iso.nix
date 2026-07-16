{ self, inputs, ... }:
{
  flake-file.inputs = {
    nixos-generators = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixos-generators";
    };

    nixos-images.url = "github:Swarsel/nixos-images/main";
    smallpkgs.url = "github:nixos/nixpkgs/08fcb0dcb59df0344652b38ea6326a2d8271baff?narHash=sha256-HXIQzULIG/MEUW2Q/Ss47oE3QrjxvpUX7gUl4Xp6lnc%3D&shallow=1";
  };

  perSystem =
    { pkgs, system, ... }:
    {
      packages = {
        keygen = inputs.nixos-generators.nixosGenerate {
          inherit pkgs system;
          format =
            {
              aarch64-linux = "sd-aarch64-installer";
              x86_64-linux = "install-iso";
            }
            .${system};
          modules = [
            inputs.home-manager.nixosModules.home-manager
            "${self}/hosts/utility/policestation"
          ];
        };
        # nix build --print-out-paths --no-link .#live-iso
        live-iso = inputs.nixos-generators.nixosGenerate {
          inherit pkgs system;
          format =
            {
              aarch64-linux = "sd-aarch64-installer";
              x86_64-linux = "install-iso";
            }
            .${system};
          modules = [
            inputs.home-manager.nixosModules.home-manager
            "${self}/hosts/utility/drugstore"
          ];
          specialArgs = { inherit self; };
        };
        # nix build --print-out-paths --no-link .#pnap-kexec --system <system>
        swarsel-kexec =
          (inputs.smallpkgs.legacyPackages.${system}.nixos [
            {
              imports = [ "${self}/hosts/utility/brickroad" ];
              _file = __curPos.file;
              system.kexec-installer.name = "swarsel-kexec";
            }
            inputs.nixos-images.nixosModules.kexec-installer
          ]).config.system.build.kexecInstallerTarball;

      };
    };
}
