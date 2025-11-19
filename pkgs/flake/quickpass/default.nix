{ self, name, writeShellApplication, libnotify, pass, wtype }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ libnotify pass wtype ];
  text = builtins.readFile "${self}/files/scripts/${name}.sh";
}
