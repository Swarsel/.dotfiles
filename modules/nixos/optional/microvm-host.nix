{ config, lib, ... }:
{
  config = lib.mkIf (config.guests != { }) {

    systemd.tmpfiles.settings."15-microvms" = builtins.listToAttrs (
      map
        (path: {
          name = "${lib.optionalString config.swarselsystems.isImpermanence "/persist"}/microvms/${path}";
          value = {
            d = {
              group = "kvm";
              user = "microvm";
              mode = "0750";
            };
          };
        })
        (builtins.attrNames config.guests)
    );

  };
}
