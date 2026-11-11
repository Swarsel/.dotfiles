{
  flake.modules.homeManager.spotify-player.config = {
    swarselsystems.enabledHomeModules = [ "spotify-player" ];
    programs.spotify-player.enable = true;
  };
}
