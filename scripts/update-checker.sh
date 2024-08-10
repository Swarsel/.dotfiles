updates="$(cd ~/.dotfiles && nix flake lock --update-input nixpkgs && nix build .#nixosConfigurations."$HOSTNAME".config.system.build.toplevel && nvd diff /run/current-system ./result | grep -c '\[U')"

tooltip="System updated"
if [[ $updates != 0 ]]; then
	tooltip=$(cd ~/.dotfiles && nvd diff /run/current-system ./result | grep -e '\[U' | awk '{ for (i=3; i<NF; i++) printf $i " "; if (NF >= 3) print $NF; }' ORS='\\n' )
fi

echo "{ \"text\":\"$updates\", \"tooltip\":\"$tooltip\" }"
