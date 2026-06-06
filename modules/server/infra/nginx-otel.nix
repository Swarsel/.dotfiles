{
  flake-file.inputs.nginx-otel = {
    url = "github:djvcom/nix-nginx-otel";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.nginx-otel =
    { inputs, lib, ... }:
    {
      imports = lib.optionals (inputs ? nginx-otel) [
        inputs.nginx-otel.nixosModules.default
        ({ config, globals, ... }: {
          services.nginx.otel = {
            enable = true;
            serviceName = "nginx-${config.node.name}";
            endpoint = "127.0.0.1:${toString globals.services.alloy.extraConfig.otlpGrpcPort}";
          };
        })
      ];
    };
}
