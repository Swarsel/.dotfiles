{ self, lib, systems, inputs, outputs, ... }:
{

  mkIfElseList = p: yes: no: lib.mkMerge [
    (lib.mkIf p yes)
    (lib.mkIf (!p) no)
  ];

  mkIfElse = p: yes: no: if p then yes else no;

  forAllSystems = lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  pkgsFor = lib.genAttrs (import systems) (system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    }
  );

  forEachSystem = f: lib.genAttrs (import systems) (system: f lib.swarselsystems.pkgsFor.${system});

  mkFullHost = host: type: {
    ${host} =
      let
        systemFunc = if (type == "nixos") then lib.nixosSystem else inputs.nix-darwin.lib.darwinSystem;
      in
      systemFunc {
        specialArgs = { inherit inputs outputs lib self; };
        modules = [
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          inputs.impermanence.nixosModules.impermanence
          inputs.lanzaboote.nixosModules.lanzaboote
          "${self}/hosts/${type}/${host}"
        ] ++
        # toto (deployment sandbox) & iso should never receive general configuration
        (if (host == "toto" || host == "iso") then [ ] else
        (
          # sync & winters (servers) should not receive common non-server config
          (if (host == "winters" || host == "sync") then [ ] else [
            "${self}/profiles/${type}/common"
            inputs.stylix.nixosModules.stylix
            inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
            inputs.nix-topology.nixosModules.default
          ]) ++ (if (type == "nixos") then [
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.users.swarsel.imports = (
                # sync & winters (servers) should not receive common non-server config
                if (host == "winters" || host == "sync") then [ ] else [
                  "${self}/profiles/home/common"
                ]
              ) ++ [
                inputs.sops-nix.homeManagerModules.sops
                inputs.nix-index-database.hmModules.nix-index
              ] ++ (builtins.attrValues outputs.homeManagerModules);
            }
          ] else [
            "${self}/profiles/darwin/nixos/common"
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager.users."leon.schwarzaeugl".imports = [
                "${self}/profiles/darwin/home"
              ] ++ (builtins.attrValues outputs.homeManagerModules);
            }
          ]) ++ (builtins.attrValues outputs.nixosModules) ++ (builtins.attrValues outputs.homeManagerModules)
        ));
      };
  };

  mkHalfHost = host: type: pkgs: {
    ${host} =
      let
        systemFunc = if (type == "home") then inputs.home-manager.lib.homeManagerConfiguration else inputs.nix-on-droid.lib.nixOnDroidConfiguration;
      in
      systemFunc
        {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs outputs lib self; };
          modules = [ "${self}/hosts/${type}/${host}" ];
        };
  };

  mkFullHostConfigs = hosts: type: lib.foldl (acc: set: acc // set) { } (lib.map (host: lib.swarselsystems.mkFullHost host type) hosts);

  mkHalfHostConfigs = hosts: type: pkgs: lib.foldl (acc: set: acc // set) { } (lib.map (host: lib.swarselsystems.mkHalfHost host type pkgs) hosts);

  readHosts = type: lib.attrNames (builtins.readDir "${self}/hosts/${type}");
  readNix = type: lib.filter (name: name != "default.nix") (lib.attrNames (builtins.readDir "${self}/${type}"));

  mkApps = system: names: self: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = {
        type = "app";
        program = "${self.packages.${system}.${name}}/bin/${name}";
      };
    })
    names);

  mkPackages = names: pkgs: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = pkgs.callPackage "${self}/pkgs/${name}" { inherit self name; };
    })
    names);


  mkModules = names: type: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = import "${self}/modules/${type}/${name}";
    })
    names);

  mkTemplates = names: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = {
        path = "${self}/templates/${name}";
        description = "${name} project ";
      };
    })
    names);

  mkImports = names: baseDir: lib.map (name: "${self}/${baseDir}/${name}") names;

  eachMonitor = _: monitor: {
    inherit (monitor) name;
    value = builtins.removeAttrs monitor [ "workspace" "name" "output" ];
  };

  eachOutput = _: monitor: {
    inherit (monitor) name;
    value = builtins.removeAttrs monitor [ "mode" "name" "scale" "transform" "position" ];
  };

}
