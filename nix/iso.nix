{ self, inputs, ... }:
{
  perSystem = { pkgs, system, ... }:
    {
      # nix build --print-out-paths --no-link .#images.<target-system>.live-iso
      packages.live-iso = inputs.nixos-generators.nixosGenerate {
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
    };
}
