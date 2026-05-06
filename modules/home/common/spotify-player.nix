_:
let
  moduleName = "spotify-player";
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "spotify-player" ];
    programs.${moduleName} = {
      enable = true;
    };
  };

}
