{ self, lib, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${self}/profiles/home/public"
    "${m}/home/common/emacs.nix"
    "${m}/home/common/env.nix"
    "${m}/home/common/git.nix"
    "${m}/home/common/mail.nix"
    "${m}/home/common/obsidian.nix"
    "${m}/home/common/ssh.nix"
  ];

  swarselsystems.trayApplets.obsidian.enable = lib.swarselsystems.mkStrong true;
}
