{ lib, den, ... }:
{
  den = {
    schema.user.classes = lib.mkDefault [ "homeManager" ];
    ctx.user.includes = [ den.provides.mutual-provider ];
    default = {
      nixos = { lib, minimal, ... }: {
        users.mutableUsers = lib.mkIf (!minimal) (lib.mkDefault false);
        system.stateVersion = lib.mkDefault "23.05";
      };
      homeManager = {
        home.stateVersion = lib.mkDefault "23.05";
      };
      includes = [
        den.provides.define-user
        den.provides.nixpkgs
      ];
    };
  };
}
