{ inputs, ... }:
{
  den.aspects.boot = {
    nixos = { pkgs, ... }: {
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
