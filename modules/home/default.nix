let
  moduleNames = [
    "laptop"
    "hardware"
    "monitors"
    "input"
    "nixos"
    "darwin"
    "waybar"
    "startup"
    "wallpaper"
    "filesystem"
    "firefox"
  ];

  mkImports = names: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = import ./${name}.nix;
    })
    names);

in
mkImports moduleNames
