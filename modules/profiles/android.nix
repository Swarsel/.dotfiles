{ config, lib, ... }:
let
  fmods = config.flake.modules;
  pickH = names: builtins.attrValues (lib.getAttrs names fmods.homeManager);
in
{
  flake.modules.nixOnDroid = {
    profile-base = {
      imports = [
        fmods.nixOnDroid.settings
        fmods.nixOnDroid.packages
      ];
      home-manager.config.imports = pickH [
        "cli-programs"
        "cli-tools"
        "zsh"
      ];
    };
    profile-personal = {
      imports = [ fmods.nixOnDroid.droid-switch ];
      home-manager.config.imports = pickH [
        "direnv"
        "eza"
        "git"
        "nix-index"
        "nix-your-shell"
        "ssh"
        "starship"
      ];
    };
  };
}
