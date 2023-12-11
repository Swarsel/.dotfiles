# flake.nix
{
  description = "CUDA environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
    llvm = pkgs.llvmPackages_latest;
  in {
    devShells.${system}.default = pkgs.mkShell {

      packages = with pkgs; [
        # gcc
        #builder
        # cmake
        # gnumake
        #headers
        clang-tools
        #lsp
        # llvm.libstdcxxClang
        # cudaPackages.cuda_nvcc
        #tools
        cppcheck
        valgrind
        doxygen
        cudatoolkit

        (pkgs.python3.withPackages (python-pkgs: [
          python-pkgs.numpy
          python-pkgs.pandas
          python-pkgs.scipy
          python-pkgs.matplotlib
          python-pkgs.requests
          python-pkgs.debugpy
          python-pkgs.python-lsp-server
        ]))
      ];
      hardeningDisable = ["all"];
      # ...

    };
  };
}
