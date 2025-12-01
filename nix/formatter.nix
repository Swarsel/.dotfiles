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
        shfmt = {
          enable = true;
          indent_size = 4;
          simplify = true;
          # needed to replicate what my Emacs shfmt does
          # there is no builtin option for space-redirects
          package = pkgs.symlinkJoin {
            name = "shfmt";
            buildInputs = [ pkgs.makeWrapper ];
            paths = [ pkgs.shfmt ];
            postBuild = ''
              wrapProgram $out/bin/shfmt \
              --add-flags '-sr'
            '';
          };
        };
        shellcheck.enable = true;
      };
      settings.formatter.shellcheck.options = [
        "--shell"
        "bash"
      ];
    };
  };
}
