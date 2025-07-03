{ self, inputs, ... }:
{
  flake = { config, ... }:
    let
      inherit (self) outputs;
      inherit (outputs) lib;
      # lib = (inputs.nixpkgs.lib // inputs.home-manager.lib).extend  (_: _: { swarselsystems = import "${self}/lib" { inherit self lib inputs outputs; inherit (inputs) systems; }; });

      mkNixosHost = { minimal }: name:
        lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib self minimal; inherit (config) globals nodes; };
          modules = [
            inputs.disko.nixosModules.disko
            inputs.sops-nix.nixosModules.sops
            inputs.impermanence.nixosModules.impermanence
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.nix-topology.nixosModules.default
            inputs.home-manager.nixosModules.home-manager
            "${self}/hosts/nixos/${name}"
            "${self}/profiles/nixos"
            "${self}/modules/nixos"
            {
              node.name = name;
              node.secretsDir = ../hosts/nixos/${name}/secrets;
            }
          ];
        };

      mkDarwinHost = { minimal }: name:
        inputs.nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs outputs lib self minimal; inherit (config) globals nodes; };
          modules = [
            # inputs.disko.nixosModules.disko
            # inputs.sops-nix.nixosModules.sops
            # inputs.impermanence.nixosModules.impermanence
            # inputs.lanzaboote.nixosModules.lanzaboote
            # inputs.fw-fanctrl.nixosModules.default
            # inputs.nix-topology.nixosModules.default
            inputs.home-manager.darwinModules.home-manager
            "${self}/hosts/darwin/${name}"
            "${self}/modules/nixos/darwin"
            # needed for infrastructure
            "${self}/modules/nixos/common/meta.nix"
            "${self}/modules/nixos/common/globals.nix"
            {
              node.name = name;
              node.secretsDir = ../hosts/darwin/${name}/secrets;
            }
          ];
        };

      mkHalfHost = name: type: pkgs: {
        ${name} =
          let
            systemFunc = if (type == "home") then inputs.home-manager.lib.homeManagerConfiguration else inputs.nix-on-droid.lib.nixOnDroidConfiguration;
          in
          systemFunc
            {
              inherit pkgs;
              extraSpecialArgs = { inherit inputs outputs lib self; };
              modules = [ "${self}/hosts/${type}/${name}" ];
            };
      };

      mkHalfHostConfigs = hosts: type: pkgs: lib.foldl (acc: set: acc // set) { } (lib.map (name: mkHalfHost name type pkgs) hosts);
      nixosHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir "${self}/hosts/nixos"));
      darwinHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir "${self}/hosts/darwin"));
    in
    {
      nixosConfigurations = lib.genAttrs nixosHosts (mkNixosHost {
        minimal = false;
      });
      nixosConfigurationsMinimal = lib.genAttrs nixosHosts (mkNixosHost {
        minimal = true;
      });
      darwinConfigurations = lib.genAttrs darwinHosts (mkDarwinHost {
        minimal = false;
      });
      darwinConfigurationsMinimal = lib.genAttrs darwinHosts (mkDarwinHost {
        minimal = true;
      });

      # TODO: Build these for all architectures
      homeConfigurations = mkHalfHostConfigs (lib.swarselsystems.readHosts "home") "home" lib.swarselsystems.pkgsFor.x86_64-linux;
      nixOnDroidConfigurations = mkHalfHostConfigs (lib.swarselsystems.readHosts "android") "android" lib.swarselsystems.pkgsFor.aarch64-linux;

      diskoConfigurations.default = import "${self}/files/templates/hosts/nixos/disk-config.nix";

      nodes = config.nixosConfigurations // config.darwinConfigurations;

    };
}
