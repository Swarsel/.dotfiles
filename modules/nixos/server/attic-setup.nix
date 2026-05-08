{ lib, config, pkgs, globals, ... }:

{
  config = {
    swarselsystems.enabledServerModules = [ "attic-setup" ];

    environment.systemPackages = with pkgs; [
      attic-client
    ];

    sops = {
      secrets = {
        attic-cache-key = { };
      };
      templates = {
        "attic-env".content = ''
          DOMAIN=https://${globals.services.attic.domain}
          TOKEN=${config.sops.placeholder.attic-cache-key}
        '';
      };
    };

    systemd.services.attic-cache-setup = {
      description = "Ensure attic is authenticated to cache";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = [
          config.sops.templates.attic-env.path
        ];
        Restart = "on-failure";
        RestartSec = 60;
        RemainAfterExit = true;
      };
      script =
        let
          attic = lib.getExe pkgs.attic-client;
          sed = lib.getExe pkgs.gnused;
          configFile = "/root/.config/attic/config.toml";
        in
        ''
          set -eu

          needs_auth() {
            if [ ! -f "${configFile}" ]; then
              return 0
            fi

            stored_token=$(${sed} -n '/^\[servers\.${config.swarselsystems.mainUser}\]/,/^\[/{ /^token[[:space:]]*=/{ s/.*=[[:space:]]*"//; s/".*//; p; q } }' "${configFile}")

            if [ -z "$stored_token" ]; then
              return 0
            fi

            if [ "$stored_token" = "$TOKEN" ]; then
              return 1  # tokens match, no auth needed
            fi

            return 0  # tokens differ, need auth
          }

          if needs_auth; then
            echo "Authenticating to attic cache..."
            ${attic} login ${config.swarselsystems.mainUser} "$DOMAIN" "$TOKEN" --set-default
            ${attic} use ${config.swarselsystems.mainUser}
          else
            echo "Cache already authenticated with matching token, skipping."
          fi
        '' + lib.optionalString (config.users.users ? buildbot) ''
          echo "Copying attic config to buildbot user..."
          install -d -m 700 -o buildbot -g buildbot /home/buildbot/.config/attic
          install -m 600 -o buildbot -g buildbot ${configFile} /home/buildbot/.config/attic/config.toml
        '';

    };

  };

}
