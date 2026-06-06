{
  flake.modules.homeManager.sharedoptions = { lib, config, nixosConfig ? null, ... }:
    let
      # mirrorAttrs = lib.mapAttrs (_: v: lib.mkDefault v) nixosConfig.swarselsystems;
      mkDefaultCommonAttrs = base: defaults:
        lib.mapAttrs (_: v: lib.mkDefault v)
          (lib.filterAttrs (k: _: base ? ${k}) defaults);
    in
    {
      options.swarselsystems = {
        homeSopsSecrets = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
          default = { };
          description = ''
            sops secrets needed by home-manager features; routed to the home-manager sops module (for standalone hosts) or nixos sops (faster activation).
          '';
        };
        homeSopsTemplates = lib.mkOption {
          type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.anything);
          default = { };
          description = ''
            sops templates needed by home-manager features; see homeSopsSecrets.
          '';
        };
        inputs = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
          default = { };
        };
        monitors = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
          default = { };
        };
        keybindings = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
        };
        startup = lib.mkOption {
          type = lib.types.listOf (lib.types.attrsOf lib.types.str);
          default = [ ];
        };
        kyria = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
          default = {
            "36125:53060:splitkb.com_splitkb.com_Kyria_rev3" = {
              xkb_layout = "us";
              xkb_variant = "altgr-intl";
            };
            "7504:24926:Kyria_Keyboard" = {
              xkb_layout = "us";
              xkb_variant = "altgr-intl";
            };
          };
          internal = true;
        };
        standardinputs = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
          default = lib.recursiveUpdate (lib.recursiveUpdate config.swarselsystems.touchpad config.swarselsystems.kyria) config.swarselsystems.inputs;
          internal = true;
        };
        touchpad = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
          default = { };
          internal = true;
        };
        swayfxConfig = lib.mkOption {
          type = lib.types.str;
          default = ''
            blur enable
            blur_xray disable
            blur_passes 1
            blur_radius 1
            shadows enable
            corner_radius 2
            titlebar_separator disable
            default_dim_inactive 0.02
          '';
          internal = true;
        };
      };
      # config.swarselsystems = mirrorAttrs;
      config.swarselsystems = lib.mkIf (nixosConfig != null) (mkDefaultCommonAttrs config.swarselsystems (nixosConfig.swarselsystems or { }));
    };
}
