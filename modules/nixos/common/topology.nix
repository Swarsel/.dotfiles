{ inputs, lib, ... }:
{
  options.swarselsystems.info = lib.mkOption {
    type = lib.types.str;
    default = "";
  };

  imports = lib.optionals (inputs ? nix-topology) [
    inputs.nix-topology.nixosModules.default
    ({ lib, config, ... }: {
      topology = {
        id = config.node.name;
        self = {
          hardware.info = config.swarselsystems.info;
          icon = lib.mkIf config.swarselsystems.isLaptop "devices.laptop";
        };
      };
    })
  ];
}
