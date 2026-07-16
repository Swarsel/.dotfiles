{
  self,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.pre-commit-hooks = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:cachix/git-hooks.nix";
  };
}
// lib.optionalAttrs (inputs ? pre-commit-hooks) {
  imports = [
    inputs.pre-commit-hooks.flakeModule
  ];

  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    {
      pre-commit = {
        check.enable = true;
        settings = {
          addGcRoot = true;
          hooks = {
            check-added-large-files.enable = true;
            check-case-conflicts.enable = true;
            check-executables-have-shebangs.enable = true;
            check-merge-conflicts.enable = true;
            check-shebang-scripts-are-executable.enable = false;
            deadnix.enable = true;
            destroyed-symlinks = {
              enable = true;
              entry = lib.getExe' pkgs.python3Packages.pre-commit-hooks "destroyed-symlinks";
            };
            detect-private-keys = {
              enable = true;
              excludes = [
                "files/public/certs"
                "files/public/age"
              ];
            };
            end-of-file-fixer.enable = true;
            fix-byte-order-marker.enable = true;
            flake-checker.enable = true;
            forbid-new-submodules.enable = true;
            mixed-line-endings.enable = true;
            modules-tangled = {
              enable = true;
              always_run = true;
              description = "Ensure every file under modules/ is tangled from SwarselSystems.org";
              entry = lib.getExe self.packages.${system}.check-modules-tangled;
              name = "modules-tangled";
              pass_filenames = false;
            };
            org-custom-ids = {
              enable = true;
              description = "Generate a :CUSTOM_ID: for every org heading that is missing one";
              entry = lib.getExe self.packages.${system}.check-org-custom-ids;
              files = "^SwarselSystems\\.org$";
              name = "org-custom-ids";
              pass_filenames = true;
            };
            org-in-sync = {
              enable = true;
              always_run = true;
              description = "Ensure SwarselSystems.org is in sync with its tangled files";
              entry = lib.getExe self.packages.${system}.check-org-in-sync;
              name = "org-in-sync";
              pass_filenames = false;
            };
            shellcheck = {
              enable = true;
              entry = "${pkgs.shellcheck}/bin/shellcheck --shell=bash";
            };
            shfmt = {
              enable = true;
              entry = "${pkgs.shfmt}/bin/shfmt -i 4 -sr -d -s -l";
            };
            statix.enable = true;
            topology-in-sync = {
              enable = true;
              description = "Ensure topology.png and topology_small.png are committed together";
              entry = lib.getExe self.packages.${system}.check-topology-in-sync;
              files = "^files/topology/topology(_small)?\\.png$";
              name = "topology-in-sync";
              pass_filenames = false;
            };
            treefmt.enable = true;
            trim-trailing-whitespace.enable = true;
          };
        };
      };
    };
}
