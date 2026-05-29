{ lib, pkgs, config, ... }:
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

  piaUp = pkgs.writeShellApplication {
    name = "pia-netns-up";
    runtimeInputs = with pkgs; [ iproute2 wireguard-tools curl jq coreutils gnused gawk systemd ];
    text = ''
      set -euo pipefail

      NETNS="${cfg.namespace}"
      WG_IFACE="wg-${cfg.namespace}"
      STATE_DIR="/run/pia"
      CA_CERT="${piaCaCert}"
      REGION="${cfg.region}"

      install -d -m 0700 "$STATE_DIR"
      install -d -m 0755 "/etc/netns/$NETNS"

      PIA_USER="$(head -n1 "${cfg.credentialsFile}")"
      PIA_PASS="$(tail -n1 "${cfg.credentialsFile}")"

      echo "Authenticating with PIA..."
      TOKEN_RESP=$(curl -sS --connect-timeout 10 --max-time 30 \
        --location --request POST \
        --header "Content-Type: application/json" \
        --data "{\"username\":\"$PIA_USER\",\"password\":\"$PIA_PASS\"}" \
        "https://www.privateinternetaccess.com/api/client/v2/token")
      TOKEN=$(echo "$TOKEN_RESP" | jq -er '.token')

      echo "Fetching region servers..."
      REGION_DATA=$(curl -sS --connect-timeout 10 --max-time 30 \
        "https://serverlist.piaservers.net/vpninfo/servers/v6" \
        | head -n1 | jq -er ".regions[] | select(.id==\"$REGION\")")

      SERVER_IP=$(echo "$REGION_DATA" | jq -er '.servers.wg[0].ip')
      SERVER_HOST=$(echo "$REGION_DATA" | jq -er '.servers.wg[0].cn')

      echo "Generating WireGuard keys..."
      WG_PRIV=$(wg genkey)
      WG_PUB=$(echo "$WG_PRIV" | wg pubkey)

      echo "Registering public key with PIA ($SERVER_HOST)..."
      WG_RESP=$(curl -sS --connect-timeout 10 --max-time 30 \
        --connect-to "$SERVER_HOST::$SERVER_IP:" \
        --cacert "$CA_CERT" -G \
        --data-urlencode "pt=$TOKEN" \
        --data-urlencode "pubkey=$WG_PUB" \
        "https://$SERVER_HOST:1337/addKey")

      [ "$(echo "$WG_RESP" | jq -r '.status')" = "OK" ] || {
        echo "addKey failed: $WG_RESP" >&2; exit 1;
      }

      PEER_IP=$(echo "$WG_RESP" | jq -r '.peer_ip')
      SERVER_KEY=$(echo "$WG_RESP" | jq -r '.server_key')
      SERVER_PORT=$(echo "$WG_RESP" | jq -r '.server_port')
      DNS=$(echo "$WG_RESP" | jq -r '.dns_servers[0]')

      ${lib.optionalString cfg.dns ''
        echo "nameserver $DNS" > "/etc/netns/$NETNS/resolv.conf"
      ''}

      ip netns list | awk '{print $1}' | grep -qx "$NETNS" || ip netns add "$NETNS"
      ip -n "$NETNS" link set lo up

      ip link del "$WG_IFACE" 2>/dev/null || true
      ip -n "$NETNS" link del "$WG_IFACE" 2>/dev/null || true

      ip link add "$WG_IFACE" type wireguard
      wg set "$WG_IFACE" private-key <(echo "$WG_PRIV")
      wg set "$WG_IFACE" peer "$SERVER_KEY" \
        endpoint "$SERVER_IP:$SERVER_PORT" \
        allowed-ips 0.0.0.0/0,::/0 \
        persistent-keepalive 25

      ip link set "$WG_IFACE" netns "$NETNS"
      ip -n "$NETNS" addr add "$PEER_IP" dev "$WG_IFACE"
      ip -n "$NETNS" link set mtu 1420 up dev "$WG_IFACE"
      ip -n "$NETNS" route add default dev "$WG_IFACE"

      echo "WireGuard tunnel up; peer_ip=$PEER_IP dns=$DNS"

      ${lib.optionalString cfg.portForwarding.enable ''
        echo "Requesting forwarded port..."
        for attempt in 1 2 3 4 5; do
          PF_RESP=$(ip netns exec "$NETNS" curl -sS --connect-timeout 5 --max-time 10 \
            --connect-to "$SERVER_HOST::$SERVER_IP:" \
            --cacert "$CA_CERT" -G \
            --data-urlencode "token=$TOKEN" \
            "https://$SERVER_HOST:19999/getSignature") || PF_RESP=""
          if [ "$(echo "$PF_RESP" | jq -r '.status' 2>/dev/null)" = "OK" ]; then
            break
          fi
          echo "getSignature attempt $attempt failed; retrying..." >&2
          sleep 3
        done

        [ "$(echo "$PF_RESP" | jq -r '.status' 2>/dev/null)" = "OK" ] || {
          echo "getSignature failed after retries: $PF_RESP" >&2; exit 1;
        }

        PAYLOAD=$(echo "$PF_RESP" | jq -r '.payload')
        SIGNATURE=$(echo "$PF_RESP" | jq -r '.signature')
        PORT=$(echo "$PAYLOAD" | base64 -d | jq -r '.port')

        echo -n "$PORT" > "${cfg.portForwarding.portFile}"
        chmod 0644 "${cfg.portForwarding.portFile}"
        echo "Forwarded port: $PORT"

        bind_port() {
          local resp
          resp=$(ip netns exec "$NETNS" curl -sS --connect-timeout 5 --max-time 10 \
            --connect-to "$SERVER_HOST::$SERVER_IP:" \
            --cacert "$CA_CERT" -G \
            --data-urlencode "payload=$PAYLOAD" \
            --data-urlencode "signature=$SIGNATURE" \
            "https://$SERVER_HOST:19999/bindPort") || return 1
          [ "$(echo "$resp" | jq -r '.status')" = "OK" ] || return 1
          echo "bindPort ok: $(echo "$resp" | jq -r '.message')"
        }

        bind_port

        systemd-notify --ready --status="PIA tunnel up, port $PORT forwarded"

        while true; do
          sleep 880
          if ! bind_port; then
            echo "bindPort failed; exiting to let systemd restart" >&2
            exit 1
          fi
        done
      ''}

      ${lib.optionalString (!cfg.portForwarding.enable) ''
        systemd-notify --ready --status="PIA tunnel up (no port forwarding)"
        # No port forwarding requested; keep the unit alive so the netns stays up
        while true; do sleep 86400; done
      ''}
    '';
  };

  piaDown = pkgs.writeShellApplication {
    name = "pia-netns-down";
    runtimeInputs = with pkgs; [ iproute2 coreutils ];
    text = ''
      NETNS="${cfg.namespace}"
      WG_IFACE="wg-${cfg.namespace}"
      ip -n "$NETNS" link del "$WG_IFACE" 2>/dev/null || true
      ip link del "$WG_IFACE" 2>/dev/null || true
      ip netns del "$NETNS" 2>/dev/null || true
      rm -f "/etc/netns/$NETNS/resolv.conf"
      rmdir "/etc/netns/$NETNS" 2>/dev/null || true
      ${lib.optionalString cfg.portForwarding.enable ''rm -f "${cfg.portForwarding.portFile}"''}
    '';
  };
in
{
  options.services.pia-netns = {
    enable = lib.mkEnableOption "PIA WireGuard VPN inside a Linux network namespace";

    namespace = lib.mkOption {
      type = lib.types.str;
      default = "pia";
    };

    region = lib.mkOption {
      type = lib.types.str;
      example = "sweden";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "File with PIA username on line 1 and password on line 2.";
    };

    dns = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    portForwarding = {
      enable = lib.mkEnableOption "PIA port forwarding with keepalive";

      portFile = lib.mkOption {
        type = lib.types.path;
        default = "/run/pia/forwarded-port";
        description = "Where the forwarded port number is written (mode 0644).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [ "wireguard" ];

    systemd.services.pia-netns = {
      description = "PIA WireGuard tunnel in network namespace";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        NotifyAccess = "exec";
        ExecStart = lib.getExe piaUp;
        ExecStop = lib.getExe piaDown;
        Restart = "on-failure";
        RestartSec = "30s";
        TimeoutStartSec = "120s";
      };
    };
  };
}
