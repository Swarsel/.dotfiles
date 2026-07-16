# heavily inspired by https://github.com/nulladmin1/nix-flake-templates/blob/main/cpp-cmake/flake.nix
{
  description = "C++ Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = forEachSystem (system: import nixpkgs { inherit system; });

      pname = "name";
    in
    {
      apps = forEachSystem (system: {
        default = {
          program = "${self.packages.${system}.default}/bin/${pname}";
          type = "app";
        };
      });

      devShells = forEachSystem (system: {
        default = pkgsFor.${system}.mkShell {
          packages = with pkgsFor.${system}; [
            libllvm
            cmake
            gtest
            cppcheck
            valgrind
            doxygen
            clang-tools
            # cudatoolkit
          ];
        };
      });

      formatter = forEachSystem (system: pkgsFor.${system}.nixpgks-fmt);

      packages = forEachSystem (system: {
        default = pkgsFor.${system}.stdenv.mkDerivation {
          inherit pname;
          buildInputs = with pkgsFor.${system}; [
            gtest
          ];
          nativeBuildInputs = with pkgsFor.${system}; [
            cmake
          ];
          src = ./.;
          version = "0.1.0";
        };
      });
    };
}
