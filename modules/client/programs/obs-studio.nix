{
  flake.modules.homeManager.obs-studio =
    let
      moduleName = "obs-studio";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "obs-studio" ];
        programs.${moduleName}.enable = true;
      };
    };
}
