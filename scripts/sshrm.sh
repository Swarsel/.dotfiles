HISTFILE="$HOME"/.histfile

last_ssh_cmd=$(grep -E "ssh " "$HISTFILE" | sed -E 's/^: [0-9]+:[0-9]+;//' | grep "^ssh " | tail -1)
host=$(echo "$last_ssh_cmd" | sed -E 's/.*ssh ([^@ ]+@)?([^ ]+).*/\2/')

if [[ -n $host ]]; then
    echo "Removing SSH host key for: $host"
    ssh-keygen -R "$host"
else
    echo "No valid SSH command found in history."
fi
