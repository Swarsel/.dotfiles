{
  flake.modules.homeManager.sharedoptions =
    {
      config,
      lib,
      nixosConfig ? null,
      ...
    }:
    let
      # mirrorAttrs = lib.mapAttrs (_: v: lib.mkDefault v) nixosConfig.swarselsystems;
      mkDefaultCommonAttrs =
        base: defaults: lib.mapAttrs (_: v: lib.mkDefault v) (lib.filterAttrs (k: _: base ? ${k}) defaults);
    in
    {
      options.swarselsystems = {
        homeSopsSecrets = lib.mkOption {
          default = { };
          description = ''
            sops secrets needed by home-manager features; routed to the home-manager sops module (for standalone hosts) or nixos sops (faster activation).
          '';
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        };
        homeSopsTemplates = lib.mkOption {
          default = { };
          description = ''
            sops templates needed by home-manager features; see homeSopsSecrets.
          '';
          type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.anything);
        };
        inputs = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        };
        keybindings = lib.mkOption {
          default = { };
          type = lib.types.attrsOf lib.types.str;
        };
        kyria = lib.mkOption {
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
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        };
        monitors = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        };
        standardinputs = lib.mkOption {
          default = lib.recursiveUpdate (lib.recursiveUpdate config.swarselsystems.touchpad config.swarselsystems.kyria) config.swarselsystems.inputs;
          internal = true;
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        };
        startup = lib.mkOption {
          default = [ ];
          type = lib.types.listOf (lib.types.attrsOf lib.types.str);
        };
        swayfxConfig = lib.mkOption {
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
          type = lib.types.str;
        };
        touchpad = lib.mkOption {
          default = { };
          internal = true;
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        };
      };
      # config.swarselsystems = mirrorAttrs;
      config.swarselsystems = lib.mkIf (nixosConfig != null) (
        mkDefaultCommonAttrs config.swarselsystems (nixosConfig.swarselsystems or { })
      );
    };
}
