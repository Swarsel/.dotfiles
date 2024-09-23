{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnupg
    nix-index
    ssh-to-age
    git
  ];
}
