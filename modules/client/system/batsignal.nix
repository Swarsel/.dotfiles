{
  flake.modules.homeManager.batsignal =
    let
      moduleName = "batsignal";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "batsignal" ];
        services.${moduleName} = {
          enable = true;
          extraArgs = [
            "-W"
            "  Consider charging the battery"
            "-C"
            "  Battery is low; plug in charger now"
            "-D"
            "  Device will lose power in a few seconds"
            "-c"
            "10"
            "-d"
            "5"
          ];
        };
      };
    };
}
