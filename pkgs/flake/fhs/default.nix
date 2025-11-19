{ name, pkgs, ... }:
let
  base = pkgs.appimageTools.defaultFhsEnvArgs;
in
pkgs.buildFHSEnv (base // {
  inherit name;
  targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [ pkgs.pkg-config ];
  profile = "export FHS=1";
  runScript = "zsh";
  extraOutputsToInstall = [ "dev" ];
})
