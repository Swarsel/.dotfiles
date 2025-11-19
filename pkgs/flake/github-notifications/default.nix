{ name, writeShellApplication, jq, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ jq ];
  text = ''
    count=$(curl -u Swarsel:"$(cat "$GITHUB_NOTIFICATION_TOKEN_PATH")" https://api.github.com/notifications | jq '. | length')

    if [[ "$count" != "0" ]]; then
        echo "{\"text\":\"$count\"}"
    fi
  '';
}
