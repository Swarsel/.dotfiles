{ inputs, ... }:
{
  den.aspects.boot = { pkgs, ... }: {
    nixos = {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      environment.systemPackages = [
        pkgs.sbctl
      ];

      boot = {
        lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
          configurationLimit = 6;
        };
      };
    };
  };
}
