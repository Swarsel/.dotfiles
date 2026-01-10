{ name, writeShellApplication, ... }:

writeShellApplication {
  inherit name;
  text = ''

    if [ "$#" -lt 3 ]; then
      echo "Usage: $0 <host> <arch_path> <service1> [service2 ...]" >&2
      echo "Example: $0 hintbooth hosts/nixos/x86_64-linux adguardhome nginx" >&2
      exit 1
    fi

    HOST="$1"
    ARCH_PATH="$2"
    shift 2

    for service in "$@"; do
      cat <<EOF
      - path_regex: ''${ARCH_PATH}/''${HOST}/secrets/''${service}/[^/]+\.(yaml|json|env|ini|enc)\$
        key_groups:
        - pgp:
          - *swarsel
          age:
          - *''${HOST}
          - *''${HOST}-''${service}

    EOF
    done
  '';
}
