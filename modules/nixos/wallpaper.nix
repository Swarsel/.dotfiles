{ self, lib, ... }:

{
  options.swarselsystems.wallpaper = lib.mkOption {
    type = lib.types.path;
    default = "${self}/wallpaper/lenovowp.png";
  };
}
