{
  flake.modules.homeManager.nixgl =
    {
      inputs,
      config,
      lib,
      pkgs,
      nixosConfig ? null,
      ...
    }:
    {
      options.swarselsystems = {
        isSecondaryGpu = lib.mkEnableOption "device has a secondary GPU";
        secondaryGpuCard = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
      };
      config = {
        swarselsystems.enabledHomeModules = [ "nixgl" ];
        targets.genericLinux.nixGL = lib.mkIf (nixosConfig == null) (
          {
            defaultWrapper = "mesa";
            installScripts = [
              "mesa"
              "mesaPrime"
            ];
            packages =
              (import "${inputs.nixgl}/default.nix" {
                inherit pkgs;
                enable32bits = pkgs.stdenv.hostPlatform.isx86_64;
                enableIntelX86Extensions = pkgs.stdenv.hostPlatform.isx86_64;
              }).override
                {
                  pcre = pkgs.writeShellApplication {
                    name = "pcregrep";
                    text = ''exec ${lib.getExe' pkgs.pcre2 "pcre2grep"} "$@"'';
                  };
                };
            vulkan.enable = false;
          }
          // lib.optionalAttrs config.swarselsystems.isSecondaryGpu {
            offloadWrapper = "mesaPrime";
            prime = {
              card = config.swarselsystems.secondaryGpuCard;
              installScript = "mesa";
            };
          }
        );
      };
    };
}
