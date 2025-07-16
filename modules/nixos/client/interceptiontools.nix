{ lib, config, pkgs, ... }:
{
  options.swarselmodules.interceptionTools = lib.mkEnableOption "interception tools config";
  config = lib.mkIf config.swarselmodules.interceptionTools {
    # Make CAPS work as a dual function ESC/CTRL key
    services.interception-tools = {
      enable = true;
      udevmonConfig =
        let
          dualFunctionKeysConfig = builtins.toFile "dual-function-keys.yaml" ''
            TIMING:
              TAP_MILLISEC: 200
              DOUBLE_TAP_MILLISEC: 0

            MAPPINGS:
              - KEY: KEY_CAPSLOCK
                TAP: KEY_ESC
                HOLD: KEY_LEFTCTRL
          '';
        in
        ''
          - JOB: |
              ${pkgs.interception-tools}/bin/intercept -g $DEVNODE \
                | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${dualFunctionKeysConfig} \
                | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE
            DEVICE:
              EVENTS:
                EV_KEY: [KEY_CAPSLOCK]
        '';
    };
  };
}
