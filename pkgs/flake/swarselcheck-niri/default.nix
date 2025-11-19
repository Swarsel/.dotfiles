{ self, name, writeShellApplication, kitty, element-desktop, vesktop, spotify-player, jq }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ kitty element-desktop vesktop spotify-player jq ];
  text = builtins.readFile "${self}/files/scripts/${name}.sh";
}
