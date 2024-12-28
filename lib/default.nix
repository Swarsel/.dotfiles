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

  pkgsFor = lib.genAttrs (import systems) (
    system:
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
        modules = [ "${self}/hosts/${type}/${host}" ];
      };
  };

  mkHalfHost = host: type: pkgs: {
    ${host} =
      let
        systemFunc = if (type == "home") then inputs.home-manager.lib.homeManagerConfiguration else inputs.nix-on-droid.lib.nixOnDroidConfiguration;
      in
      systemFunc {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs outputs; };
        modules = [ "${self}/hosts/${type}/${host}" ];
      };
  };

  mkFullHostConfigs = hosts: type: lib.foldl (acc: set: acc // set) { } (lib.map (host: lib.swarselsystems.mkFullHost host type) hosts);
  mkHalfHostConfigs = hosts: type: pkgs: lib.foldl (acc: set: acc // set) { } (lib.map (host: lib.swarselsystems.mkFullHost host type pkgs) hosts);

  readHosts = type: lib.attrNames (builtins.readDir "${self}/hosts/${type}");

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
      value = pkgs.callPackage "${self}/pkgs/${name}" { inherit self; };
    })
    names);


  mkModules = names: type: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = import "${self}/modules/${type}/${name}.nix";
    })
    names);

  eachMonitor = _: monitor: {
    inherit (monitor) name;
    value = builtins.removeAttrs monitor [ "workspace" "name" "output" ];
  };

  eachOutput = _: monitor: {
    inherit (monitor) name;
    value = builtins.removeAttrs monitor [ "mode" "name" "scale" "transform" "position" ];
  };

}
