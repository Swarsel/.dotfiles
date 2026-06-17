# heavily inspired from https://github.com/oddlama/nix-config/blob/d42cbde676001a7ad8a3cace156e050933a4dcc3/pkgs/deploy.nix
{ name, bc, nix-output-monitor, writeShellApplication, ... }:
writeShellApplication {
  runtimeInputs = [ bc nix-output-monitor ];
  inherit name;
  text = ''
      set -euo pipefail
      shopt -s lastpipe # allow cmd | readarray

      function die() {
          echo "error: $*" >&2
    exit 1
      }
      function show_help() {
          echo 'Usage: deploy [OPTIONS] [--] <host,...> [ACTION]'
          echo "Builds, pushes and activates nixosConfigurations on target systems."
          echo ""
          echo 'ACTION:'
          echo '  switch          [default] Switch immediately to the new configuration and make it the boot default'
          echo '  boot            Make the configuration the new boot default'
          echo "  test            Activate the configuration but don't make it the boot default"
          echo "  dry-activate    Don't activate, just show what would be done"
          echo ""
          echo 'OPTIONS: [passed to nix build]'
          echo '  Use -- to separate options from host/action when passing options with values'
      }

      function time_start() {
          T_START=$(date +%s.%N)
      }

      function time_next() {
          T_END=$(date +%s.%N)
          T_LAST=$(${bc}/bin/bc <<< "scale=1; ($T_END - $T_START)/1")
          T_START="$T_END"
      }

      USER_FLAKE_DIR=$(git rev-parse --show-toplevel 2> /dev/null || pwd) ||
          die "Could not determine current working directory. Something went very wrong."
      [[ -e "$USER_FLAKE_DIR/flake.nix" ]] ||
          die "Could not determine location of your project's flake.nix. Please run this at or below your main directory containing the flake.nix."
      cd "$USER_FLAKE_DIR"

      [[ $# -gt 0 ]] || {
          show_help
          exit 1
      }

      OPTIONS=()
      POSITIONAL_ARGS=()

      args=("$@")
      sep=-1
      for i in "''${!args[@]}"; do
          [[ "''${args[$i]}" == "--" ]] && sep=$i && break
      done

      if [[ $sep -ge 0 ]]; then
          OPTIONS=("''${args[@]:0:$sep}")
          POSITIONAL_ARGS=("''${args[@]:$((sep+1))}")
          for opt in "''${OPTIONS[@]}"; do
              case "$opt" in
              "help"|"--help"|"-help"|"-h") show_help; exit 1 ;;
              esac
          done
      else
          while [[ $# -gt 0 ]]; do
              case "$1" in
              "help"|"--help"|"-help"|"-h")
                  show_help
                  exit 1
                  ;;
              -*) OPTIONS+=("$1") ;;
              *)
                  POSITIONAL_ARGS+=("$1")
                  shift
                  POSITIONAL_ARGS+=("$@")
                  break
                  ;;
              esac
              shift
          done
      fi

      [[ ''${#POSITIONAL_ARGS[@]} -ge 1 ]] ||
          die "Missing argument: <hosts...>"
      [[ ''${#POSITIONAL_ARGS[@]} -le 2 ]] ||
          die "Too many arguments given."

      tr , '\n' <<< "''${POSITIONAL_ARGS[0]}" | sort -u | readarray -t HOSTS
      ACTION="''${POSITIONAL_ARGS[1]-switch}"

      declare -A TOPLEVEL_FLAKE_PATHS
      for host in "''${HOSTS[@]}"; do
          TOPLEVEL_FLAKE_PATHS["$host"]=".#nixosConfigurations.$host.config.system.build.toplevel"
      done

      current_host=$(hostname)

      ssh_control_dir=$(mktemp -d)
      ssh_mux_opts=(-o ControlMaster=auto -o ControlPath="$ssh_control_dir/%C" -o ControlPersist=yes)
      function cleanup_ssh() {
          for host in "''${HOSTS[@]}"; do
              [ "$host" = "$current_host" ] && continue
              ssh -o ControlPath="$ssh_control_dir/%C" -O exit "$host" 2>/dev/null || true
          done
          rm -rf "$ssh_control_dir"
      }
      trap cleanup_ssh EXIT

      for host in "''${HOSTS[@]}"; do
          [ "$host" = "$current_host" ] && continue
          echo -e "\033[1;36m  Connecting \033[m🔑 \033[34m$host\033[m \033[90m(touch your key once)\033[m"
          ssh "''${ssh_mux_opts[@]}" "$host" -- true
      done

      time_start

      declare -A TOPLEVEL_STORE_PATHS
      for host in "''${HOSTS[@]}"; do
          toplevel="''${TOPLEVEL_FLAKE_PATHS["$host"]}"
          # Make sudo call to get prompt out of the way
          sudo echo "[1;36m    Building [m📦 [34m$host[m"
          build_log=$(mktemp)
          store_path_file=$(mktemp)
          set +e
          nix build --no-link --print-out-paths "''${OPTIONS[@]}" --show-trace --log-format internal-json -v "$toplevel" >"$store_path_file" 2> >(tee "$build_log" | ${nix-output-monitor}/bin/nom --json >&2)
          build_rc=$?
          set -e
          wait 2>/dev/null || true
          if [[ $build_rc -ne 0 ]]; then
              if grep -q '\[nixbuild\.net\] error: Authorization failed' "$build_log"; then
                  echo -e "\033[1;36m    nixbuild.net failed: retrying locally... \033[m"
                  nix build --builders "" --no-link --print-out-paths "''${OPTIONS[@]}" --show-trace --log-format internal-json -v "$toplevel" >"$store_path_file" 2> >(${nix-output-monitor}/bin/nom --json >&2) ||
                      die "Failed to get derivation path for $host from ''${TOPLEVEL_FLAKE_PATHS["$host"]}"
                  wait 2>/dev/null || true
              else
                  rm -f "$build_log" "$store_path_file"
                  die "Failed to get derivation path for $host from ''${TOPLEVEL_FLAKE_PATHS["$host"]}"
              fi
          fi
          store_path=$(<"$store_path_file")
          rm -f "$build_log" "$store_path_file"
          TOPLEVEL_STORE_PATHS["$host"]="$store_path"
          time_next
          echo "[1;32m       Built [m✅ [34m$host[m [33m''${TOPLEVEL_STORE_PATHS["$host"]}[m [90min ''${T_LAST}s[m"
      done

      for host in "''${HOSTS[@]}"; do
          store_path="''${TOPLEVEL_STORE_PATHS["$host"]}"

          if [ "$host" = "$current_host" ]; then
              echo -e "\033[1;36m    Running locally for $host... \033[m"
              ssh_prefix="sudo"
          else
              echo -e "\033[1;36m     Copying \033[m➡️  \033[34m$host\033[m"
              NIX_SSHOPTS="''${ssh_mux_opts[*]}" nix copy --to "ssh://$host" "$store_path"
              time_next
              echo -e "\033[1;32m      Copied \033[m✅  \033[34m$host\033[m \033[90min ''${T_LAST}s\033[m"
              ssh_prefix="ssh ''${ssh_mux_opts[*]} $host --"
          fi

          echo -e "\033[1;36m    Applying \033[m⚙️  \033[34m$host\033[m"
          prev_system=$($ssh_prefix readlink -e /nix/var/nix/profiles/system)
          if [[ "$ACTION" == "switch" || "$ACTION" == "boot" ]]; then
              $ssh_prefix /run/current-system/sw/bin/nix-env --profile /nix/var/nix/profiles/system --set "$store_path" ||
                  die "Failed to set system profile"
          else
              echo -e "\033[1;36m    $ACTION: Not setting system profile \033[m"


          fi
          $ssh_prefix "$store_path"/bin/switch-to-configuration "$ACTION" ||
              echo "Error while activating new system" >&2

          if [[ -n $prev_system ]]; then
              $ssh_prefix nvd --color always diff "$prev_system" "$store_path" || true
          fi

          time_next
          echo -e "\033[1;32m     Applied \033[m✅  \033[34m$host\033[m \033[90min ''${T_LAST}s\033[m"
      done
  '';
}
