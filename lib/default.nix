{ self, lib, systems, inputs, outputs, ... }:
let
  linuxUser = "swarsel";
  macUser = "leon.schwarzaeugl";
in
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
      overlays = [ self.overlays.default ];
      config.allowUnfree = true;
    }
  );

  # mkUser = name: {
  #   config.users.users.${name} = {
  #     group = name;
  #     isSystemUser = true;
  #   };

  #   config.users.groups.${name} = {};
  # };

  mkTrueOption = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  mkStrong = lib.mkOverride 60;

  getSecret = filename: lib.strings.trim (builtins.readFile "${filename}");

  forEachSystem = f: lib.genAttrs (import systems) (system: f lib.swarselsystems.pkgsFor.${system});

  mkFullHost = host: type: {
    ${host} =
      let
        systemFunc = if (type == "nixos") then lib.nixosSystem else inputs.nix-darwin.lib.darwinSystem;
      in
      systemFunc {
        specialArgs = { inherit inputs outputs lib self; };
        modules = [
          {
            node.name = host;
            node.secretsDir = ../hosts/${type}/${host}/secrets;
          }
          # put inports here that are for all hosts
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          inputs.impermanence.nixosModules.impermanence
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.fw-fanctrl.nixosModules.default
          "${self}/hosts/${type}/${host}"
          {
            _module.args.primaryUser = linuxUser;
          }
        ] ++
        (if (host == "iso") then [
          inputs.nix-topology.nixosModules.default
        ] else
          ([
            # put nixos imports here that are for all servers and normal hosts
            inputs.nix-topology.nixosModules.default
            "${self}/modules/${type}/common"
            inputs.stylix.nixosModules.stylix
            inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
          ] ++ (if (type == "nixos") then [
            inputs.home-manager.nixosModules.home-manager
            "${self}/profiles/nixos"
            "${self}/modules/nixos/server"
            "${self}/modules/nixos/optional"
            {
              home-manager.users."${linuxUser}".imports = [
                # put home-manager imports here that are for all normal hosts
                "${self}/modules/home/common"
                "${self}/modules/home/server"
                "${self}/modules/home/optional"
                "${self}/profiles/home"
              ];
            }
          ] else [
            # put nixos imports here that are for darwin hosts
            "${self}/modules/darwin/nixos/common"
            "${self}/profiles/darwin"
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager.users."${macUser}".imports = [
                # put home-manager imports here that are for darwin hosts
                "${self}/modules/darwin/home"
                "${self}/modules/home/server"
                "${self}/modules/home/optional"
                "${self}/profiles/home"
              ];
            }
          ])
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
        meta = {
          description = "Custom app ${name}.";
        };
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

  mkProfiles = names: type: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = import "${self}/profiles/${type}/${name}";
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
