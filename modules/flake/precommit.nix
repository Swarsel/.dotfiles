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
              excludes = [ "files/public/age" ];
            };
            end-of-file-fixer.enable = true;
            fix-byte-order-marker.enable = true;
            flake-checker.enable = true;
            flake-file-in-sync = {
              enable = true;
              entry = "${pkgs.writeShellScript "flake-file-in-sync" ''
                if [[ -z $NIX_BUILD_TOP ]]; then
                    nix build --no-link --print-build-logs .#checks.${system}.check-flake-file
                fi
              ''}";
              files = "\\.nix$";
              pass_filenames = false;
            };
            forbid-new-submodules.enable = true;
            mixed-line-endings.enable = true;
            modules-tangled = {
              enable = true;
              always_run = true;
              entry = "${pkgs.writeShellScript "modules-tangled" ''
                untangled=$(comm -23 <(find modules -type f | sort) <(grep -oP ':tangle\s+\Kmodules/\S+' SwarselSystems.org | sort -u))
                if [[ -n $untangled ]]; then
                    echo "not tangled from SwarselSystems.org:"
                    echo "$untangled"
                    exit 1
                fi
              ''}";
              pass_filenames = false;
            };
            org-custom-ids = {
              enable = true;
              entry = "${pkgs.writeScript "org-custom-ids" ''
                #!${pkgs.emacs-nox}/bin/emacs --script
                ;; -*- lexical-binding: t -*-
                (require 'org-id)

                (dolist (file command-line-args-left)
                  (with-current-buffer (find-file-noselect file)
                    (org-map-entries
                     (lambda ()
                       (unless (org-entry-get nil "CUSTOM_ID")
                         (org-entry-put nil "CUSTOM_ID" (org-id-new "h")))))
                    (save-buffer)))
              ''}";
              files = "^SwarselSystems\\.org$";
              pass_filenames = true;
            };
            org-in-sync = {
              enable = true;
              always_run = true;
              entry = "${lib.getExe self.packages.${system}.swarsel-sync-org} --dry-run";
              pass_filenames = false;
            };
            pii-lock = {
              enable = true;
              always_run = true;
              entry = "${lib.getExe inputs.piix.packages.${system}.pii} check";
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
              entry = "${pkgs.writeShellScript "topology-in-sync" ''
                if [[ $# -eq 1 ]]; then
                    echo "$1 was staged without the other topology image."
                    exit 1
                fi
              ''}";
              files = "^files/topology/topology(_small)?\\.png$";
              pass_filenames = true;
            };
            treefmt.enable = true;
            trim-trailing-whitespace.enable = true;
          };
        };
      };
    };
}
