inputs:
inputs.flake-parts.lib.mkFlake { inherit inputs; } {
  imports = [
    ./flake-file.nix
    ./globals.nix
    ./hosts.nix
    ./topology.nix
    ./devshell.nix
    ./apps.nix
    ./packages.nix
    ./overlays.nix
    ./lib.nix
    ./templates.nix
    ./formatter.nix
    ./modules.nix
    ./iso.nix
  ];
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
}
