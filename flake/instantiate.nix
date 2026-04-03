{ self, inputs, ... }:
{
  flake = { config, ... }: {
    instantiateNixos = { minimal }: configName: arch: { modules }:
      let
        inherit (self) outputs;
        inherit (outputs) lib homeLib;
        mkStrong = lib.mkOverride 60;
      in
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs self homeLib configName arch minimal;
          inherit (config.pkgs.${arch}) lib;
          inherit (config) nodes topologyPrivate;
          globals = config.globals.${arch};
          type = "nixos";
          withHomeManager = true;
          extraModules = [ "${self}/modules-clone/nixos/common/globals.nix" ];
        };
        modules = modules ++ [
          inputs.disko.nixosModules.disko
          inputs.home-manager.nixosModules.home-manager
          inputs.impermanence.nixosModules.impermanence
          inputs.microvm.nixosModules.host
          inputs.microvm.nixosModules.microvm
          inputs.nix-index-database.nixosModules.nix-index
          inputs.nix-minecraft.nixosModules.minecraft-servers
          inputs.nix-topology.nixosModules.default
          inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
          inputs.simple-nixos-mailserver.nixosModules.default
          inputs.sops.nixosModules.sops
          inputs.stylix.nixosModules.stylix
          inputs.swarsel-nix.nixosModules.default
          inputs.nixos-nftables-firewall.nixosModules.default
          inputs.pia.nixosModules.default
          inputs.niritiling.nixosModules.default
          inputs.noctoggle.nixosModules.default
          (inputs.nixos-extra-modules + "/modules/guests")
          (inputs.nixos-extra-modules + "/modules/interface-naming.nix")
          "${self}/hosds/nixos/${arch}/${configName}"
          "${self}/profiles-clone/nixos"
          "${self}/modules-clone/nixos"
          {
            _module.args.dns = inputs.dns;

            microvm.guest.enable = lib.mkDefault false;

            networking.hostName = mkStrong configName;

            node = {
              name = lib.mkForce configName;
              arch = lib.mkForce arch;
              type = lib.mkForce "nixos";
              secretsDir = ../hosts/nixos/${arch}/${configName}/secrets;
              configDir = ../hosts/nixos/${arch}/${configName};
              lockFromBootstrapping = lib.mkIf (!minimal) (mkStrong true);
            };

            swarselprofiles = {
              minimal = lib.mkIf minimal (mkStrong true);
            };

            swarselmodules.server = {
              ssh = lib.mkIf (!minimal) (mkStrong true);
            };

            swarselsystems = {
              mainUser = mkStrong "swarsel";
            };
          }
        ];
      };
  };
}
