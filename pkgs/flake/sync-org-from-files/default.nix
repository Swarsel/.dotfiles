{ name, self, python313, writeShellApplication, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ python313 ];
  text = ''
    exec ${python313}/bin/python3 ${self}/files/scripts/sync-org-from-files.py "$@"
  '';
}
