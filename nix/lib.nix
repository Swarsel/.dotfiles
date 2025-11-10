{ self, inputs, ... }:
let
  swarselsystems =
    let
      inherit (inputs) systems;
      inherit (inputs.nixpkgs) lib;
    in
    rec {
      cidrToSubnetMask = cidr:
        let
          prefixLength = lib.toInt (lib.last (lib.splitString "/" cidr));
          bits = lib.genList (i: if i < prefixLength then 1 else 0) 32;
          octets = lib.genList
            (i:
              let
                octetBits = lib.sublist (i * 8) 8 bits;
                octetValue = lib.foldl (acc: bit: acc * 2 + bit) 0 octetBits;
              in
              octetValue
            ) 4;
          subnetMask = lib.concatStringsSep "." (map toString octets);
        in
        subnetMask;

      mkIfElseList = p: yes: no: lib.mkMerge [
        (lib.mkIf p yes)
        (lib.mkIf (!p) no)
      ];

      mkIfElse = p: yes: no: if p then yes else no;

      pkgsFor = lib.genAttrs (import systems) (system:
        import inputs.nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
          config.allowUnfree = true;
        }
      );

      toCapitalized = str:
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


      mkTrueOption = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      mkStrong = lib.mkOverride 60;

      # forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
      forEachLinuxSystem = f: lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f pkgsFor.${system});

      readHosts = type: lib.attrNames (builtins.readDir "${self}/hosts/${type}");
      readNix = type: lib.filter (name: name != "default.nix") (lib.attrNames (builtins.readDir "${self}/${type}"));

      mkImports = names: baseDir: lib.map (name: "${self}/${baseDir}/${name}") names;
    };
in
{
  flake = _:
    {
      lib = inputs.nixpkgs.lib.extend (_: _: {
        inherit (inputs.home-manager.lib) hm;
        inherit swarselsystems;
      });

      swarselsystemsLib = swarselsystems;
      homeLib = self.outputs.lib;
    };
}
