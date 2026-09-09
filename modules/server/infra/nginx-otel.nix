{
  flake-file.inputs.nginx-otel = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:djvcom/nix-nginx-otel";
  };

  flake.modules.nixos.nginx-otel =
    {
      inputs,
      config,
      lib,
      pkgs,
      globals,
      ...
    }:
    let
      nginxCompat = pkgs.nginx.overrideAttrs (old: {
        configureFlags = old.configureFlags ++ [ "--with-compat" ];
      });
      nginxOtelModule = pkgs.callPackage "${inputs.nginx-otel}/nginx-otel-module.nix" {
        nginx = nginxCompat;
      };
    in
    {
      config = lib.mkIf (inputs ? nginx-otel) {
        services.nginx = {
          package = nginxCompat;
          appendHttpConfig = ''
            otel_service_name "nginx-${config.node.name}";
            otel_exporter {
              endpoint 127.0.0.1:${toString globals.services.alloy.extraConfig.otlpGrpcPort};
            }
            otel_trace on;
            otel_trace_context propagate;
          '';
          prependConfig = ''
            load_module ${nginxOtelModule}/lib/nginx/modules/ngx_otel_module.so;
          '';
        };
      };
    };
}
