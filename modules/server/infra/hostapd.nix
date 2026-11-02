{
  flake.modules.nixos.hostapd =
    {
      config,
      lib,
      pkgs,
      confLib,
      globals,
      utils,
      ...
    }:
    let
      inherit (config.swarselsystems) sopsFile;
      inherit (config.repo.secrets.local.networking) wifi;
      wifiVLANs = [
        "home"
        "guests"
        "iot"
      ];
      vlanId = vlanName: toString globals.networks.home-lan.vlans.${vlanName}.id;
      pskSecret = vlanName: "wifi-psk-${vlanName}";
      bridgeDevices = map (
        vlanName: "sys-subsystem-net-devices-${utils.escapeSystemdPath "br-${vlanName}"}.device"
      ) wifiVLANs;
      mkNetwork = radio: {
        inherit (wifi) ssid;
        authentication = {
          mode = "wpa2-sha1";
          wpaPskFile = config.sops.templates."hostapd.psk".path;
        };
        settings = {
          dynamic_vlan = 1;
          vlan_file = toString (
            pkgs.writeText "${radio}.vlan" (
              lib.concatMapStrings (
                vlanName: "${vlanId vlanName} ${radio}.${vlanId vlanName} br-${vlanName}\n"
              ) wifiVLANs
            )
          );
        };
      };
      wifi6 = {
        enable = true;
        multiUserBeamformer = true;
        singleUserBeamformee = true;
        singleUserBeamformer = true;
      };
    in
    {
      config = {
        swarselsystems = {
          bridgedVLANs = wifiVLANs;
          enabledServerModules = [ "hostapd" ];
        };
        topology.self = {
          services.hostapd = {
            details = lib.mapAttrs (_: radio: {
              text = "${radio.band}, channel ${toString radio.channel}";
            }) config.services.hostapd.radios;
            icon = "interfaces.wifi";
            info = "VLANs: ${lib.concatStringsSep ", " wifiVLANs}";
            name = lib.swarselsystems.toCapitalized "hostapd";
          };
          interfaces = lib.mapAttrs (_: _: { }) config.services.hostapd.radios;
        };
        globals.monitoring.systemd = confLib.mkSystemdMonitoring {
          serviceName = "hostapd-${config.node.name}";
          unit = "hostapd.service";
        };
        sops = {
          secrets = lib.genAttrs (map pskSecret wifiVLANs) (_: {
            inherit sopsFile;
          });
          templates."hostapd.psk" = {
            content = lib.concatMapStrings (
              vlanName:
              "keyid=${vlanName} vlanid=${vlanId vlanName} 00:00:00:00:00:00 ${
                config.sops.placeholder.${pskSecret vlanName}
              }\n"
            ) wifiVLANs;
            reloadUnits = [ "hostapd.service" ];
          };
        };
        services.hostapd = {
          enable = true;
          radios = {
            wlan2g = {
              inherit wifi6;
              band = "2g";
              channel = 1;
              countryCode = "AT";
              networks.wlan2g = mkNetwork "wlan2g";
              wifi4.capabilities = [
                "LDPC"
                "SHORT-GI-20"
                "TX-STBC"
                "RX-STBC1"
              ];
              wifi5.enable = false;
            };
            wlan5g = {
              band = "5g";
              channel = 36;
              countryCode = "AT";
              networks.wlan5g = mkNetwork "wlan5g";
              settings = {
                he_oper_centr_freq_seg0_idx = 42;
                vht_oper_centr_freq_seg0_idx = 42;
              };
              wifi4.capabilities = [
                "HT40+"
                "LDPC"
                "SHORT-GI-20"
                "SHORT-GI-40"
                "TX-STBC"
                "RX-STBC1"
              ];
              wifi5 = {
                capabilities = [
                  "RXLDPC"
                  "SHORT-GI-80"
                  "TX-STBC-2BY1"
                  "RX-STBC-1"
                  "MAX-A-MPDU-LEN-EXP7"
                  "RX-ANTENNA-PATTERN"
                  "TX-ANTENNA-PATTERN"
                ];
                operatingChannelWidth = "80";
              };
              wifi6 = wifi6 // {
                operatingChannelWidth = "80";
              };
            };
          };
        };
        environment.etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
          lib.mkAfter ''
            prometheus.exporter.unix "hostapd" {
              set_collectors = ["wifi"]
            }

            prometheus.scrape "hostapd" {
              targets    = prometheus.exporter.unix.hostapd.targets
              forward_to = [prometheus.remote_write.mimir.receiver]
              job_name   = "hostapd"
            }
          ''
        );
        systemd = {
          services.hostapd = {
            after = bridgeDevices;
            bindsTo = bridgeDevices;
          };
          network.links = lib.mapAttrs' (
            radio: mac:
            lib.nameValuePair "10-${radio}" {
              linkConfig = {
                Name = radio;
                NamePolicy = "keep";
              };
              matchConfig = {
                PermanentMACAddress = mac;
                Type = "wlan";
              };
            }
          ) wifi.radios;
        };
        nodes.${globals.general.monitoringServer}.services.grafana.provision.alerting.rules.settings.groups =
          let
            radios = lib.attrNames config.services.hostapd.radios;
          in
          [
            {
              folder = "Infrastructure";
              interval = "1m";
              name = "hostapd-${config.node.name}";
              orgId = 1;
              rules = [
                (confLib.mkGrafanaAlertRule {
                  expr = ''count(node_wifi_interface_frequency_hertz{host="${config.node.name}",device=~"${lib.concatStringsSep "|" radios}"} > 0) or vector(0)'';
                  summary = "fewer than ${toString (lib.length radios)} wifi radios on ${config.node.name} are operating on a channel";
                  threshold = lib.length radios;
                  title = "hostapd radio down (${config.node.name})";
                  uid = "hostapd_radio_down_${config.node.name}";
                })
              ];
            }
          ];
      };
    };
}
