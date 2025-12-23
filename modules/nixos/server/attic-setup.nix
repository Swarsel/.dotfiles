{ lib, config, pkgs, globals, ... }:

{
  options.swarselmodules.server.attic-setup = lib.mkEnableOption "enable attic setup";
  config = lib.mkIf config.swarselmodules.server.attic-setup {

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
      };
      script =
        let
          attic = lib.getExe pkgs.attic-client;
        in
        ''
          set -eu
          if ${attic} cache info ${config.swarselsystems.mainUser} >/dev/null 2>&1; then
            echo "cache already authenticated"
            exit 0
          fi
          echo "cache not authenticated, attempting login..."
          ${attic} login ${config.swarselsystems.mainUser} "$DOMAIN" "$TOKEN" --set-default
          ${attic} use ${config.swarselsystems.mainUser}
        '';

    };

  };

}
