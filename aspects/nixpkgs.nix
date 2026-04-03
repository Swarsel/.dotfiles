{ self, den, ... }:
let
  inherit (self.outputs) lib;
  nixpkgsModule = from:
    let
      config = if (from ? host) then from.host else if (from ? home) then from.home else { };
    in
    {
      nixpkgs = {
        overlays = [
          self.outputs.overlays.default
          self.outputs.overlays.stables
          self.outputs.overlays.modifications
        ] ++ lib.optionals ((from ? user) || (from ? home)) [
          (final: prev:
            let
              additions = final: _: import "${self}/pkgs/config" {
                inherit self config lib;
                pkgs = final;
                homeConfig = if (from ? user) then from.user else if (from ? home) then from.home else { };
              };
            in
            additions final prev
          )
        ];
        config = lib.mkIf (!config.isMicroVM) {
          allowUnfree = true;
        };
      };
    };

  hostAspect =
    { host }:
    {
      ${host.class} = nixpkgsModule { inherit host; };
    };

  hostUserAspect =
    { host, user }:
    {
      ${host.class} = nixpkgsModule { inherit host user; };
    };

  homeAspect =
    { home }:
    {
      ${home.class} = nixpkgsModule { inherit home; };
    };

in
{
  den.provides.nixpkgs = den.lib.parametric.exactly {
    includes = [
      hostAspect
      hostUserAspect
      homeAspect
    ];
  };
}
