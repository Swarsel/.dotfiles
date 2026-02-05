WORKSPACE=$(niri msg -j workspaces | jq -r '.[] | select(.is_active == true) | .id')

COUNT=$(niri msg -j windows | jq --argjson ws "$WORKSPACE" -r '.[] | select(.workspace_id == $ws and .is_floating == false) | .app_id' | wc -l)

while [[ $COUNT == "0" || $COUNT == "2" ]]; do
    COUNT=$(niri msg -j windows | jq --argjson ws "$WORKSPACE" -r '.[] | select(.workspace_id == $ws and .is_floating == false) | .app_id' | wc -l)
done

if [[ $COUNT == "1" ]]; then
    niri msg action maximize-column
fi
