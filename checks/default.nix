{ self, inputs, pkgs, system, ... }:
{
  pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
    src = "${self}";
    hooks = {
      check-added-large-files.enable = true;
      check-case-conflicts.enable = true;
      check-executables-have-shebangs.enable = true;
      check-shebang-scripts-are-executable.enable = false;
      check-merge-conflicts.enable = true;
      deadnix.enable = true;
      detect-private-keys.enable = true;
      end-of-file-fixer.enable = true;
      fix-byte-order-marker.enable = true;
      flake-checker.enable = true;
      forbid-new-submodules.enable = true;
      mixed-line-endings.enable = true;
      nixpkgs-fmt.enable = true;
      statix.enable = true;
      trim-trailing-whitespace.enable = true;

      destroyed-symlinks = {
        enable = true;
        entry = "${inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks}/bin/destroyed-symlinks";
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
}
