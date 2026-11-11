{
  flake.modules.nixos.topology =
    {
      inputs,
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.nix-topology.nixosModules.default ];
      options.swarselsystems.info = lib.mkOption {
        default = "";
        type = lib.types.str;
      };
      config.topology = {
        id = config.node.name;
        self = {
          hardware.info = config.swarselsystems.info;
          icon = lib.mkIf config.swarselsystems.isLaptop "devices.laptop";
        };
      };
    };
}
