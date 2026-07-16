{
  flake-file.inputs.lanzaboote = {
    inputs = {
      nixpkgs.follows = "nixpkgs";
      pre-commit.follows = "pre-commit-hooks";
    };
    url = "github:nix-community/lanzaboote";
  };

  flake.modules.nixos.lanzaboote =
    {
      inputs,
      config,
      lib,
      pkgs,
      minimal,
      ...
    }:
    let
      inherit (config.swarselsystems) isImpermanence isSecureBoot;
    in
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
      boot = {
        lanzaboote = lib.mkIf (!minimal && isSecureBoot) {
          enable = true;
          configurationLimit = 6;
          pkiBundle = "/var/lib/sbctl";
        };
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = lib.swarselsystems.mkIfElse (minimal || !isSecureBoot) (lib.mkForce true) (
            lib.mkForce false
          );
        };
      };
      environment = {
        persistence."/persist" = lib.mkIf (isImpermanence && isSecureBoot) {
          directories = [ { directory = "/var/lib/sbctl"; } ];
        };
        systemPackages = lib.mkIf isSecureBoot [
          pkgs.sbctl
        ];
      };
    };
}
