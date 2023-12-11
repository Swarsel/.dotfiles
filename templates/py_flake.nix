{
  description = "Python Flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {

      packages = [
        (pkgs.python3.withPackages (python-pkgs: [
          python-pkgs.numpy
          python-pkgs.pandas
          python-pkgs.scipy
          python-pkgs.matplotlib
          python-pkgs.requests
          python-pkgs.debugpy
          python-pkgs.flake8
          python-pkgs.gnureadline
          python-pkgs.python-lsp-server
        ]))
      ];
    };
  };
}
