updates="$( { cd /home/swarsel/.dotfiles && nix flake update && nix build .#nixosConfigurations."$(eval hostname)".config.system.build.toplevel &&  nvd diff /run/current-system ./result | grep -c '\[U'; } || true)"

alt="has-updates"
if [[ $updates -eq 0 ]]; then
    alt="updated"
fi

tooltip="System updated"
if [[ $updates != 0 ]]; then
  	tooltip=$(cd ~/.dotfiles && nvd diff /run/current-system ./result | grep -e '\[U' | awk '{ for (i=3; i<NF; i++) printf $i " "; if (NF >= 3) print $NF; }' ORS='\\n' )
    echo "{ \"text\":\"$updates\", \"alt\":\"$alt\", \"tooltip\":\"$tooltip\" }"
else
    echo "{ \"text\":\"\", \"alt\":\"$alt\", \"tooltip\":\"\" }"
fi
