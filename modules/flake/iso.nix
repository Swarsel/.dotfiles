{ self, inputs, ... }:
{
  flake-file.inputs = {
    nixos-images.url = "github:Swarsel/nixos-images/main";
    smallpkgs.url = "github:nixos/nixpkgs/08fcb0dcb59df0344652b38ea6326a2d8271baff?narHash=sha256-HXIQzULIG/MEUW2Q/Ss47oE3QrjxvpUX7gUl4Xp6lnc%3D&shallow=1";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  perSystem =
    { pkgs, system, ... }:
    {
      packages = {
        # nix build --print-out-paths --no-link .#live-iso
        live-iso = inputs.nixos-generators.nixosGenerate {
          inherit pkgs system;
          specialArgs = { inherit self; };
          modules = [
            inputs.home-manager.nixosModules.home-manager
            "${self}/install/installer-config.nix"
          ];
          format =
            {
              x86_64-linux = "install-iso";
              aarch64-linux = "sd-aarch64-installer";
            }
            .${system};
        };

        keygen = inputs.nixos-generators.nixosGenerate {
          inherit pkgs system;
          modules = [
            inputs.home-manager.nixosModules.home-manager
            "${self}/install/keygen-config.nix"
          ];
          format =
            {
              x86_64-linux = "install-iso";
              aarch64-linux = "sd-aarch64-installer";
            }
            .${system};
        };

        # nix build --print-out-paths --no-link .#pnap-kexec --system <system>
        swarsel-kexec =
          (inputs.smallpkgs.legacyPackages.${system}.nixos [
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
