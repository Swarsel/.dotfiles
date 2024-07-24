{ lib, ... }:

{
  options.swarselsystems.cpuCount = lib.mkOption {
    type = lib.types.int;
    default = 8;
  };
}
