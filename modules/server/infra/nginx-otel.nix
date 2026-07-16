{
  flake-file.inputs.nginx-otel = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:djvcom/nix-nginx-otel";
  };

  flake.modules.nixos.nginx-otel =
    { inputs, lib, ... }:
    {
      imports = lib.optionals (inputs ? nginx-otel) [
        inputs.nginx-otel.nixosModules.default
        ({ config, globals, ... }: {
          services.nginx.otel = {
            enable = true;
            endpoint = "127.0.0.1:${toString globals.services.alloy.extraConfig.otlpGrpcPort}";
            serviceName = "nginx-${config.node.name}";
          };
        })
      ];
    };
}
