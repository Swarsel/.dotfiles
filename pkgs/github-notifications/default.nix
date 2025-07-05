{ name, writeShellApplication, jq, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ jq ];
  text = ''
    count=$(curl -u Swarsel:"$(cat "$XDG_RUNTIME_DIR/secrets/github-notifications-token")" https://api.github.com/notifications | jq '. | length')

    if [[ "$count" != "0" ]]; then
        echo "{\"text\":\"$count\"}"
    fi
  '';
}
