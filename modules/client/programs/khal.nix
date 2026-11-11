{
  flake.modules.homeManager.khal =
    { pkgs, ... }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "khal" ];
        programs.khal = {
          enable = true;
          package = pkgs.khal;
        };
      };
    };
}
