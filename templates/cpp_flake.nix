# flake.nix
{
  description = "C/C++ environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    llvm = pkgs.llvmPackages_latest;
  in {
    devShells.${system}.default = pkgs.mkShell {

      packages = with pkgs; [
        gcc
        #builder
        cmake
        gnumake
        #headers
        clang-tools
        #lsp
        llvm.libstdcxxClang
        #tools
        cppcheck
        valgrind
        doxygen
      ];
      hardeningDisable = ["all"];
      # direnv does not allow aliases, use scripts as a workaround
      shellHook = ''
      PATH_add ~/.dotfiles/scripts/devShell
      '';
      # ...

    };
  };
}
