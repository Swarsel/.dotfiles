{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = { pkgs, ... }: {
    # formatter = pkgs.nixpkgs-fmt;
    # formatter is set by treefmt to:
    # formatter = lib.mkIf config.treefmt.flakeFormatter (lib.mkDefault config.treefmt.build.wrapper);
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt = {
          enable = true;
          package = pkgs.nixpkgs-fmt;
        };
        deadnix.enable = true;
        statix.enable = true;
        shellcheck.enable = true;
      };
      settings.formatter.shellcheck.options = [
        "--shell"
        "bash"
      ];
    };
  };
}
