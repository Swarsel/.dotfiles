{ lib, config, pkgs, withHomeManager, ... }:
{
  options.swarselmodules.server.packages = lib.mkEnableOption "enable packages on server";
  config = lib.mkIf config.swarselmodules.server.packages {
    environment.systemPackages = with pkgs; [
      gnupg
      nvd
      nix-output-monitor
      ssh-to-age
      git
      emacs
      vim
      sops
      tmux
      busybox
      ndisc6
      tcpdump
      swarsel-deploy
    ] ++ lib.optionals withHomeManager [
      swarsel-gens
      swarsel-switch
    ];
  };
}
