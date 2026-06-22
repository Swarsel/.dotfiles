{
  flake.modules.nixos.xserver = {
    config = {
      services.xserver = {
        xkb = {
          layout = "us";
          variant = "altgr-intl";
        };
      };
    };
  };
}
