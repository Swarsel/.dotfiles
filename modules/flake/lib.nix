{ self, inputs, ... }:
let
  swarselsystems =
    let
      inherit (inputs) systems;
      inherit (inputs.nixpkgs) lib;
      domainParts = domain: builtins.filter (part: part != "") (lib.splitString "." domain);
    in
    rec {
      inherit (inputs.piix.lib.mkPii { lock = "${self}/secrets/pii.lock"; }) importEncrypted;
      cidrToSubnetMask =
        cidr:
        let
          prefixLength = lib.toInt (lib.last (lib.splitString "/" cidr));
          bits = lib.genList (i: if i < prefixLength then 1 else 0) 32;
        in
        lib.concatMapStringsSep "." (
          i: toString (lib.foldl (acc: bit: acc * 2 + bit) 0 (lib.sublist (i * 8) 8 bits))
        ) (lib.range 0 3);
      darwinSystems = builtins.filter (lib.hasSuffix "-darwin") (import systems);
      forEachLinuxSystem = f: lib.genAttrs linuxSystems (system: f pkgsFor.${system});
      getBaseDomain = domain: lib.concatStringsSep "." (lib.drop 1 (domainParts domain));
      getSubDomain = domain: lib.concatStrings (lib.take 1 (domainParts domain));
      linuxSystems = builtins.filter (lib.hasSuffix "-linux") (import systems);
      mkStrong = lib.mkOverride 60;
      mkTrueOption = lib.mkOption {
        default = true;
        type = lib.types.bool;
      };
      pkgsFor = lib.genAttrs (import systems) (
        system:
        import inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              # matrix
              "olm-3.2.16"
            ];
          };
          overlays = [
            self.overlays.default
            self.overlays.stables
            self.overlays.modifications
          ];
        }
      );
      readNix = type: lib.remove "default.nix" (lib.attrNames (builtins.readDir "${self}/${type}"));
      root =
        subpath:
        builtins.path {
          name = builtins.baseNameOf subpath;
          path = "${self}/${subpath}";
        };
      toCapitalized =
        str:
        lib.toUpper (builtins.substring 0 1 str)
        + lib.toLower (builtins.substring 1 (builtins.stringLength str) str);
    };
in
{
  flake = {
    lib = inputs.nixpkgs.lib.extend (
      _: _: {
        inherit (inputs.home-manager.lib) hm;
        inherit swarselsystems;
      }
    );
    swarselsystemsLib = swarselsystems;
  };

  _module.args.root = swarselsystems.root;
}
