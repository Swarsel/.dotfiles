{ self, lib, systems, inputs, ... }:
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
