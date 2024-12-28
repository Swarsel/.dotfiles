{ writeShellApplication, jq, ... }:

writeShellApplication {
  name = "github-notifications";
  runtimeInputs = [ jq ];
  text = ''
    count=$(curl -u Swarsel:"$(cat /run/user/1000/secrets/github_notif)" https://api.github.com/notifications | jq '. | length')

    if [[ "$count" != "0" ]]; then
        echo "{\"text\":\"$count\"}"
    fi
  '';
}
