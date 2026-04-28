{ config, lib, confLib, ... }:
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

    systemd.services = lib.concatMapAttrs
      (guestName: _: {
        "microvm-macvtap-interfaces@${guestName}" = {
          after = [ "sys-subsystem-net-devices-vlan\\x2dservices.device" ];
          bindsTo = [ "sys-subsystem-net-devices-vlan\\x2dservices.device" ];
        };
      })
      config.guests;

    users.persistentIds.microvm = confLib.mkIds 999;

  };
}
