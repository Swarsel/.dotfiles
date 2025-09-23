{ name, writeShellApplication, ... }:
writeShellApplication {
  inherit name;
  text = ''
    set -euo pipefail
    systemctl --user stop graphical-session.target
    systemctl --user stop graphical-session-pre.target
  '';
}
