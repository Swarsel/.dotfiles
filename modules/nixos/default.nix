let
  moduleNames = [
    "wallpaper"
    "hardware"
    "setup"
    "impermanence"
    "filesystem"
    "input"
  ];

  mkImports = names: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = import ./${name}.nix;
    })
    names);

in
mkImports moduleNames
