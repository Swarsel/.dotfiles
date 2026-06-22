{
  flake.modules.nixos.server-packages =
    {
      lib,
      pkgs,
      withHomeManager,
      ...
    }:
    {
      config = {
        swarselsystems.enabledServerModules = [ "packages" ];
        environment.systemPackages =
          with pkgs;
          [
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
          ]
          ++ lib.optionals withHomeManager [
            swarsel-gens
            swarsel-switch
          ];
      };
    }

  ;
}
