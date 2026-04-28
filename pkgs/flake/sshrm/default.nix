{ name, writeShellApplication, openssh, ... }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ openssh ];
  text = ''
    HISTFILE="$HOME"/.histfile

    last_ssh_cmd=$(grep -E "ssh " "$HISTFILE" | sed -E 's/^: [0-9]+:[0-9]+;//' | grep "^ssh " | tail -1)

    if [[ -z "$last_ssh_cmd" ]]; then
        echo "No SSH command found in history."
        exit 1
    fi

    # Let ssh itself parse the arguments and resolve the hostname
    # shellcheck disable=SC2086
    host=$(''${last_ssh_cmd/ssh/ssh -G} 2>/dev/null | awk '/^hostname / {print $2}')

    if [[ -n "$host" ]]; then
        echo "Removing SSH host key for: $host"
        ssh-keygen -R "$host"
    else
        echo "No valid SSH host found in the last SSH command."
        echo "Command was: $last_ssh_cmd"
    fi
  '';
}
