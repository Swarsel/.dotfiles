{ self, inputs, ... }:
let
  swarselsystems =
    let
      inherit (inputs) systems;
      inherit (inputs.nixpkgs) lib;
    in
    rec {
      cidrToSubnetMask =
        cidr:
        let
          prefixLength = lib.toInt (lib.last (lib.splitString "/" cidr));
          bits = lib.genList (i: if i < prefixLength then 1 else 0) 32;
          octets = lib.genList (
            i:
            let
              octetBits = lib.sublist (i * 8) 8 bits;
              octetValue = lib.foldl (acc: bit: acc * 2 + bit) 0 octetBits;
            in
            octetValue
          ) 4;
          subnetMask = lib.concatStringsSep "." (map toString octets);
        in
        subnetMask;
      darwinSystems = builtins.filter (lib.hasSuffix "-darwin") (import systems);
      forEachLinuxSystem = f: lib.genAttrs linuxSystems (system: f pkgsFor.${system});
      getBaseDomain =
        domain:
        let
          parts = builtins.split "\\." domain;
          domainParts = builtins.filter (x: builtins.isString x && x != "") parts;
        in
        if builtins.length domainParts > 0 then
          builtins.concatStringsSep "." (builtins.tail domainParts)
        else
          "";
      getSubDomain =
        domain:
        let
          parts = builtins.split "\\." domain;
          domainParts = builtins.filter (x: builtins.isString x && x != "") parts;
        in
        if builtins.length domainParts > 0 then builtins.head domainParts else "";
      linuxSystems = builtins.filter (lib.hasSuffix "-linux") (import systems);
      mkIfElse =
        p: yes: no:
        if p then yes else no;
      mkIfElseList =
        p: yes: no:
        lib.mkMerge [
          (lib.mkIf p yes)
          (lib.mkIf (!p) no)
        ];
      mkImports = names: baseDir: lib.map (name: "${self}/${baseDir}/${name}") names;
      mkStrong = lib.mkOverride 60;
      mkTrueOption = lib.mkOption {
        default = true;
        type = lib.types.bool;
      };
      pkgsFor = lib.genAttrs (import systems) (
        system:
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            self.overlays.default
            self.overlays.stables
            self.overlays.modifications
          ];
        }
      );
      readHosts = type: lib.attrNames (builtins.readDir "${self}/hosts/${type}");
      readNix =
        type:
        lib.filter (name: name != "default.nix" && name != "optional" && name != "darwin") (
          lib.attrNames (builtins.readDir "${self}/${type}")
        );
      toCapitalized =
        str:
        if builtins.stringLength str == 0 then
          ""
        else
          let
            first = builtins.substring 0 1 str;
            rest = builtins.substring 1 (builtins.stringLength str - 1) str;
            upper = lib.toUpper first;
            lower = lib.toLower rest;
          in
          upper + lower;
    };
in
{
  flake = {
    homeLib = self.outputs.lib;
    lib = inputs.nixpkgs.lib.extend (
      _: _: {
        inherit (inputs.home-manager.lib) hm;
        inherit swarselsystems;
      }
    );
    swarselsystemsLib = swarselsystems;
  };
}
