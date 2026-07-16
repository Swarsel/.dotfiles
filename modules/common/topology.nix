{
  flake.modules.nixos.topology =
    { inputs, lib, ... }:
    {
      imports = lib.optionals (inputs ? nix-topology) [
        inputs.nix-topology.nixosModules.default
        ({ config, lib, ... }: {
          topology = {
            id = config.node.name;
            self = {
              hardware.info = config.swarselsystems.info;
              icon = lib.mkIf config.swarselsystems.isLaptop "devices.laptop";
            };
          };
        })
      ];
      options.swarselsystems.info = lib.mkOption {
        default = "";
        type = lib.types.str;
      };
    };
}
