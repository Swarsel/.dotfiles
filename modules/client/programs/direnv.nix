{
  flake.modules.homeManager.direnv = {
    config = {
      swarselsystems.enabledHomeModules = [ "direnv" ];
      programs.direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
      };
    };
  };
}
