{ name, nix-output-monitor, writeShellApplication, ... }:
writeShellApplication {
  runtimeInputs = [ nix-output-monitor ];
  inherit name;
  text = ''
    set -euo pipefail
    [[ "$#" -ge 1 ]] \
      || { echo "usage: build <HOST>..." >&2; exit 1; }
    HOSTS=()
    for h in "$@"; do
      HOSTS+=(".#nixosConfigurations.$h.config.system.build.toplevel")
    done
    nom build --no-link --print-out-paths --show-trace "''${HOSTS[@]}"
  '';
}
