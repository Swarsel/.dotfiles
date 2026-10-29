{
  flake.modules.nixos.nginx-otel =
    {
      config,
      pkgs,
      globals,
      ...
    }:
    {
      services.nginx = {
        additionalModules = [
          (pkgs.nginxModules.otel.overrideAttrs {
            patches = [ ../../../files/patches/nginx-otel-cpp20.patch ];
          })
        ];
        appendHttpConfig = ''
          otel_service_name "nginx-${config.node.name}";
          otel_exporter {
            endpoint 127.0.0.1:${toString globals.services.alloy.extraConfig.otlpGrpcPort};
          }
          otel_trace on;
          otel_trace_context propagate;
        '';
      };
    };
}
