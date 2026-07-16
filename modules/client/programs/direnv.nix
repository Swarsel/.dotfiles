{
  flake.modules.homeManager.direnv = {
    config = {
      swarselsystems.enabledHomeModules = [ "direnv" ];
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
      };
    };
  };
}
