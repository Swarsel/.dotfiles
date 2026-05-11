_:
{
  config = {
    services = {
      blueman = {
        enable = true;
        withApplet = false;
      };
      hardware.bolt.enable = true;
    };
  };
}
