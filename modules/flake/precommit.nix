{
  self,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.pre-commit-hooks = {
    url = "github:cachix/git-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
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
            check-shebang-scripts-are-executable.enable = false;
            check-merge-conflicts.enable = true;
            deadnix.enable = true;
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
            nixfmt-rfc-style.enable = true;
            statix.enable = true;
            trim-trailing-whitespace.enable = true;
            treefmt.enable = true;

            destroyed-symlinks = {
              enable = true;
              entry = "${inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks}/bin/destroyed-symlinks";
            };

            org-custom-ids = {
              enable = true;
              name = "org-custom-ids";
              description = "Generate a :CUSTOM_ID: for every org heading that is missing one";
              entry = lib.getExe self.packages.${system}.check-org-custom-ids;
              files = "^SwarselSystems\\.org$";
              pass_filenames = true;
            };

            topology-in-sync = {
              enable = true;
              name = "topology-in-sync";
              description = "Ensure topology.png and topology_small.png are committed together";
              entry = lib.getExe self.packages.${system}.check-topology-in-sync;
              files = "^files/topology/topology(_small)?\\.png$";
              pass_filenames = false;
            };

            org-in-sync = {
              enable = true;
              name = "org-in-sync";
              description = "Ensure SwarselSystems.org is in sync with its tangled files";
              entry = lib.getExe self.packages.${system}.check-org-in-sync;
              always_run = true;
              pass_filenames = false;
            };

            modules-tangled = {
              enable = true;
              name = "modules-tangled";
              description = "Ensure every file under modules/ is tangled from SwarselSystems.org";
              entry = lib.getExe self.packages.${system}.check-modules-tangled;
              always_run = true;
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
          };
        };
      };
    };
}
