{
  flake.modules.nixos.attic-setup =
    {
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:

    {
      config = {
        swarselsystems.enabledServerModules = [ "attic-setup" ];
        sops = {
          secrets.attic-cache-key.rekey.keyPrefix = confLib.static.sharedSecrets.common;
          templates.attic-env.content = ''
            DOMAIN=https://${globals.services.attic.domain}
            TOKEN=${config.sops.placeholder.attic-cache-key}
          '';
        };
        environment.systemPackages = with pkgs; [
          attic-client
        ];
        systemd.services.attic-cache-setup = {
          after = [ "network-online.target" ];
          description = "Log in to the attic cache";
          path = [ pkgs.attic-client ];
          script = ''
            if ! grep -qsF "\"$TOKEN\"" /root/.config/attic/config.toml; then
              attic login ${config.swarselsystems.mainUser} "$DOMAIN" "$TOKEN" --set-default
              attic use ${config.swarselsystems.mainUser}
            fi
          ''
          + lib.optionalString (config.users.users ? buildbot) ''
            install -d -m 700 -o buildbot -g buildbot /home/buildbot/.config/attic
            install -m 600 -o buildbot -g buildbot /root/.config/attic/config.toml /home/buildbot/.config/attic/config.toml
          '';
          serviceConfig = {
            EnvironmentFile = [
              config.sops.templates.attic-env.path
            ];
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = 60;
            Type = "oneshot";
          };
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];

        };

      };
      key = "swarsel/server/attic-setup";
    };
}
