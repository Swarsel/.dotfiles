{
  flake.modules.nixos.pia-netns =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      cfg = config.services.pia-netns;

      piaCaCert = pkgs.writeText "pia-ca.rsa.4096.crt" ''
        -----BEGIN CERTIFICATE-----
        MIIHqzCCBZOgAwIBAgIJAJ0u+vODZJntMA0GCSqGSIb3DQEBDQUAMIHoMQswCQYD
        VQQGEwJVUzELMAkGA1UECBMCQ0ExEzARBgNVBAcTCkxvc0FuZ2VsZXMxIDAeBgNV
        BAoTF1ByaXZhdGUgSW50ZXJuZXQgQWNjZXNzMSAwHgYDVQQLExdQcml2YXRlIElu
        dGVybmV0IEFjY2VzczEgMB4GA1UEAxMXUHJpdmF0ZSBJbnRlcm5ldCBBY2Nlc3Mx
        IDAeBgNVBCkTF1ByaXZhdGUgSW50ZXJuZXQgQWNjZXNzMS8wLQYJKoZIhvcNAQkB
        FiBzZWN1cmVAcHJpdmF0ZWludGVybmV0YWNjZXNzLmNvbTAeFw0xNDA0MTcxNzQw
        MzNaFw0zNDA0MTIxNzQwMzNaMIHoMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0Ex
        EzARBgNVBAcTCkxvc0FuZ2VsZXMxIDAeBgNVBAoTF1ByaXZhdGUgSW50ZXJuZXQg
        QWNjZXNzMSAwHgYDVQQLExdQcml2YXRlIEludGVybmV0IEFjY2VzczEgMB4GA1UE
        AxMXUHJpdmF0ZSBJbnRlcm5ldCBBY2Nlc3MxIDAeBgNVBCkTF1ByaXZhdGUgSW50
        ZXJuZXQgQWNjZXNzMS8wLQYJKoZIhvcNAQkBFiBzZWN1cmVAcHJpdmF0ZWludGVy
        bmV0YWNjZXNzLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALVk
        hjumaqBbL8aSgj6xbX1QPTfTd1qHsAZd2B97m8Vw31c/2yQgZNf5qZY0+jOIHULN
        De4R9TIvyBEbvnAg/OkPw8n/+ScgYOeH876VUXzjLDBnDb8DLr/+w9oVsuDeFJ9K
        V2UFM1OYX0SnkHnrYAN2QLF98ESK4NCSU01h5zkcgmQ+qKSfA9Ny0/UpsKPBFqsQ
        25NvjDWFhCpeqCHKUJ4Be27CDbSl7lAkBuHMPHJs8f8xPgAbHRXZOxVCpayZ2SND
        fCwsnGWpWFoMGvdMbygngCn6jA/W1VSFOlRlfLuuGe7QFfDwA0jaLCxuWt/BgZyl
        p7tAzYKR8lnWmtUCPm4+BtjyVDYtDCiGBD9Z4P13RFWvJHw5aapx/5W/CuvVyI7p
        Kwvc2IT+KPxCUhH1XI8ca5RN3C9NoPJJf6qpg4g0rJH3aaWkoMRrYvQ+5PXXYUzj
        tRHImghRGd/ydERYoAZXuGSbPkm9Y/p2X8unLcW+F0xpJD98+ZI+tzSsI99Zs5wi
        jSUGYr9/j18KHFTMQ8n+1jauc5bCCegN27dPeKXNSZ5riXFL2XX6BkY68y58UaNz
        meGMiUL9BOV1iV+PMb7B7PYs7oFLjAhh0EdyvfHkrh/ZV9BEhtFa7yXp8XR0J6vz
        1YV9R6DYJmLjOEbhU8N0gc3tZm4Qz39lIIG6w3FDAgMBAAGjggFUMIIBUDAdBgNV
        HQ4EFgQUrsRtyWJftjpdRM0+925Y6Cl08SUwggEfBgNVHSMEggEWMIIBEoAUrsRt
        yWJftjpdRM0+925Y6Cl08SWhge6kgeswgegxCzAJBgNVBAYTAlVTMQswCQYDVQQI
        EwJDQTETMBEGA1UEBxMKTG9zQW5nZWxlczEgMB4GA1UEChMXUHJpdmF0ZSBJbnRl
        cm5ldCBBY2Nlc3MxIDAeBgNVBAsTF1ByaXZhdGUgSW50ZXJuZXQgQWNjZXNzMSAw
        HgYDVQQDExdQcml2YXRlIEludGVybmV0IEFjY2VzczEgMB4GA1UEKRMXUHJpdmF0
        ZSBJbnRlcm5ldCBBY2Nlc3MxLzAtBgkqhkiG9w0BCQEWIHNlY3VyZUBwcml2YXRl
        aW50ZXJuZXRhY2Nlc3MuY29tggkAnS7684Nkme0wDAYDVR0TBAUwAwEB/zANBgkq
        hkiG9w0BAQ0FAAOCAgEAJsfhsPk3r8kLXLxY+v+vHzbr4ufNtqnL9/1Uuf8NrsCt
        pXAoyZ0YqfbkWx3NHTZ7OE9ZRhdMP/RqHQE1p4N4Sa1nZKhTKasV6KhHDqSCt/dv
        Em89xWm2MVA7nyzQxVlHa9AkcBaemcXEiyT19XdpiXOP4Vhs+J1R5m8zQOxZlV1G
        tF9vsXmJqWZpOVPmZ8f35BCsYPvv4yMewnrtAC8PFEK/bOPeYcKN50bol22QYaZu
        LfpkHfNiFTnfMh8sl/ablPyNY7DUNiP5DRcMdIwmfGQxR5WEQoHL3yPJ42LkB5zs
        6jIm26DGNXfwura/mi105+ENH1CaROtRYwkiHb08U6qLXXJz80mWJkT90nr8Asj3
        5xN2cUppg74nG3YVav/38P48T56hG1NHbYF5uOCske19F6wi9maUoto/3vEr0rnX
        JUp2KODmKdvBI7co245lHBABWikk8VfejQSlCtDBXn644ZMtAdoxKNfR2WTFVEwJ
        iyd1Fzx0yujuiXDROLhISLQDRjVVAvawrAtLZWYK31bY7KlezPlQnl/D9Asxe85l
        8jO5+0LdJ6VyOs/Hd4w52alDW/MFySDZSfQHMTIc30hLBJ8OnCEIvluVQQ2UQvoW
        +no177N9L2Y+M9TcTA62ZyMXShHQGeh20rb4kK8f+iFX8NxtdHVSkxMEFSfDDyQ=
        -----END CERTIFICATE-----
      '';

      mkForward =
        namespace: forward:
        let
          socat = [
            (lib.getExe pkgs.socat)
          ]
          ++ lib.optional (forward.idleTimeout != null) "-T${toString forward.idleTimeout}";
        in
        {
          after = [ forward.service ];
          bindsTo = [ forward.service ];
          description = "Forward port ${toString forward.port} into the ${namespace} netns";
          partOf = [ forward.service ];
          serviceConfig = {
            ExecStart = utils.escapeSystemdExecArgs (
              socat
              ++ [
                "TCP-LISTEN:${toString forward.port},${
                  lib.optionalString (forward.listenAddress != null) "bind=${forward.listenAddress},"
                }reuseaddr,fork"
                "EXEC:${lib.getExe' pkgs.iproute2 "ip"} netns exec ${namespace} ${toString socat} - TCP\\:127.0.0.1\\:${toString forward.targetPort}"
              ]
            );
            Restart = "on-failure";
            RestartSec = "5s";
            SuccessExitStatus = "143";
            Type = "simple";
          };
          wantedBy = [
            "multi-user.target"
            forward.service
          ];
        };
    in
    {
      options.services.pia-netns.tunnels = lib.mkOption {
        default = { };
        description = "PIA WireGuard tunnels, each inside its own network namespace.";
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                credentialsFile = lib.mkOption {
                  description = "File with PIA username on line 1 and password on line 2.";
                  type = lib.types.path;
                };
                forwards = lib.mkOption {
                  default = { };
                  description = "TCP forwarders from the host into the namespace, keyed by unit name.";
                  type = lib.types.attrsOf (
                    lib.types.submodule (
                      { config, ... }:
                      {
                        options = {
                          idleTimeout = lib.mkOption {
                            default = null;
                            type = lib.types.nullOr lib.types.int;
                          };
                          listenAddress = lib.mkOption {
                            default = null;
                            type = lib.types.nullOr lib.types.str;
                          };
                          port = lib.mkOption {
                            type = lib.types.port;
                          };
                          service = lib.mkOption {
                            description = "Unit inside the namespace that the forwarder is bound to.";
                            type = lib.types.str;
                          };
                          targetPort = lib.mkOption {
                            default = config.port;
                            type = lib.types.port;
                          };
                        };
                      }
                    )
                  );
                };
                netnsPath = lib.mkOption {
                  default = "/var/run/netns/${name}";
                  readOnly = true;
                  type = lib.types.str;
                };
                portForwarding = {
                  enable = lib.mkEnableOption "PIA port forwarding with keepalive";

                  portFile = lib.mkOption {
                    default = "/run/pia/${name}/forwarded-port";
                    type = lib.types.path;
                  };
                };
                region = lib.mkOption {
                  example = "sweden";
                  type = lib.types.str;
                };
                unit = lib.mkOption {
                  default = "pia-netns-${name}.service";
                  readOnly = true;
                  type = lib.types.str;
                };
              };
            }
          )
        );
      };
      config = lib.mkIf (cfg.tunnels != { }) {
        boot.kernelModules = [ "wireguard" ];

        systemd.services =
          lib.mapAttrs' (
            name: tunnel:
            lib.nameValuePair "pia-netns-${name}" {
              after = [ "network-online.target" ];
              description = "PIA WireGuard tunnel in network namespace ${name}";
              serviceConfig = {
                ExecStart = lib.getExe (
                  pkgs.writeShellApplication {
                    name = "pia-netns-${name}-up";
                    runtimeInputs = with pkgs; [
                      coreutils
                      curl
                      iproute2
                      jq
                      systemd
                      wireguard-tools
                    ];
                    text = ''
                      ok() {
                          jq -e '.status == "OK"' <<< "$1" > /dev/null || { echo "$1" >&2; exit 1; }
                      }

                      user=$(head -n1 ${tunnel.credentialsFile})
                      pass=$(tail -n1 ${tunnel.credentialsFile})
                      token=$(curl -sS --max-time 30 --location \
                        --header "Content-Type: application/json" \
                        --data "{\"username\":\"$user\",\"password\":\"$pass\"}" \
                        https://www.privateinternetaccess.com/api/client/v2/token | jq -er .token)

                      server=$(curl -sS --max-time 30 https://serverlist.piaservers.net/vpninfo/servers/v6 \
                        | head -n1 | jq -ec '.regions[] | select(.id == "${tunnel.region}") | .servers.wg[0]')
                      ip=$(jq -r .ip <<< "$server")
                      host=$(jq -r .cn <<< "$server")
                      api=(curl -sS --connect-timeout 5 --max-time 30 --cacert ${piaCaCert} --connect-to "$host::$ip:" -G)

                      private_key=$(wg genkey)
                      peer=$("''${api[@]}" \
                        --data-urlencode "pt=$token" \
                        --data-urlencode "pubkey=$(wg pubkey <<< "$private_key")" \
                        "https://$host:1337/addKey")
                      ok "$peer"

                      ip netns add ${name}
                      ip -n ${name} link set lo up
                      install -d /etc/netns/${name}
                      jq -r '"nameserver \(.dns_servers[0])"' <<< "$peer" > /etc/netns/${name}/resolv.conf

                      ip link add wg-${name} type wireguard
                      wg set wg-${name} private-key <(echo "$private_key") \
                        peer "$(jq -r .server_key <<< "$peer")" \
                        endpoint "$ip:$(jq -r .server_port <<< "$peer")" \
                        allowed-ips 0.0.0.0/0,::/0 \
                        persistent-keepalive 25
                      ip link set wg-${name} netns ${name}
                      ip -n ${name} addr add "$(jq -r .peer_ip <<< "$peer")" dev wg-${name}
                      ip -n ${name} link set wg-${name} mtu 1420 up
                      ip -n ${name} route add default dev wg-${name}
                    ''
                    + (
                      if tunnel.portForwarding.enable then
                        ''
                          signature=$(ip netns exec ${name} "''${api[@]}" --retry 5 --retry-all-errors \
                            --data-urlencode "token=$token" \
                            "https://$host:19999/getSignature")
                          ok "$signature"

                          install -d ${dirOf tunnel.portForwarding.portFile}
                          jq -r .payload <<< "$signature" | base64 -d | jq -j .port > ${tunnel.portForwarding.portFile}

                          while true; do
                              ok "$(ip netns exec ${name} "''${api[@]}" \
                                --data-urlencode "payload=$(jq -r .payload <<< "$signature")" \
                                --data-urlencode "signature=$(jq -r .signature <<< "$signature")" \
                                "https://$host:19999/bindPort")"
                              systemd-notify --ready --status="port $(cat ${tunnel.portForwarding.portFile}) forwarded"
                              sleep 880
                          done
                        ''
                      else
                        ''
                          systemd-notify --ready
                          while sleep 60; do
                              handshake=$(ip netns exec ${name} wg show wg-${name} latest-handshakes | cut -f2)
                              if (( handshake > 0 && $(date +%s) - handshake > 300 )); then
                                  echo "handshake older than 300s" >&2
                                  exit 1
                              fi
                          done
                        ''
                    );
                  }
                );
                ExecStopPost = [
                  "-${pkgs.iproute2}/bin/ip netns del ${name}"
                  "-${pkgs.iproute2}/bin/ip link del wg-${name}"
                  "${pkgs.coreutils}/bin/rm -rf /etc/netns/${name} ${tunnel.portForwarding.portFile}"
                ];
                NotifyAccess = "exec";
                Restart = "on-failure";
                RestartSec = "30s";
                TimeoutStartSec = "120s";
                Type = "notify";
              };
              wantedBy = [ "multi-user.target" ];
              wants = [ "network-online.target" ];
            }
          ) cfg.tunnels
          // lib.concatMapAttrs (name: tunnel: lib.mapAttrs (_: mkForward name) tunnel.forwards) cfg.tunnels;
      };
    };
}
