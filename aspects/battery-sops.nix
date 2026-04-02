{ lib, den, ... }:
let
  hostContext = { name, args, class }: { host }: {
    nixos.sops.secrets.${name} = lib.mkIf (!host.isPublic) args // lib.optionalAttrs (class == "homeManager") { owner = host.mainUser; };
  };

  # deadnix: skip
  hostUserContext = { name, args, class }: { host, user }: {
    nixos.sops.secrets.${name} = lib.mkIf (!host.isPublic) args // lib.optionalAttrs (class == "homeManager") { owner = host.mainUser; };
  };

  homeContext = { name, args }: { home }: {
    homeManager.sops.secrets.${name} = lib.mkIf (!home.isPublic) args;
  };

in
{
  den.provides.sops = { name, args, class ? "homeManager" }: den.lib.parametric.exactly {
    includes = [
      (hostContext { inherit name args class; })
      (hostUserContext { inherit name args class; })
    ] ++ lib.optional (class == "homeManager") (homeContext { inherit name args; });
  };
}
