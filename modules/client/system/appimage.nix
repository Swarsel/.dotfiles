{
  flake.modules.nixos.appimage.config.programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
