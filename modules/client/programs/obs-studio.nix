{
  flake.modules.homeManager.obs-studio.config = {
    swarselsystems.enabledHomeModules = [ "obs-studio" ];
    programs.obs-studio.enable = true;
  };
}
