{ lib, config, ... }:
{
  options.swarselsystems.info = lib.mkOption {
    type = lib.types.str;
    default = "";
  };
  config.topology = {
    id = config.node.name;
    self = {
      hardware.info = config.swarselsystems.info;
      icon = lib.mkIf config.swarselsystems.isLaptop "devices.laptop";
    };
  };
}
