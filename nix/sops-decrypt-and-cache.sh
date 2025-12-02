#!/usr/bin/env bash
# adapted from https://github.com/oddlama/nix-config/blob/main/nix/rage-decrypt-and-cache.sh
set -euo pipefail

print_out_path=false
if [[ $1 == "--print-out-path" ]]; then
    print_out_path=true
    shift
fi

file="$1"
shift

basename="${file%".enc"}"
# store path prefix or ./ if applicable
[[ $file == "/nix/store/"* ]] && basename="${basename#*"-"}"
[[ $file == "./"* ]] && basename="${basename#"./"}"

# Calculate a unique content-based identifier (relocations of
# the source file in the nix store should not affect caching)
new_name="$(sha512sum "$file")"
new_name="${new_name:0:32}-${basename//"/"/"%"}"

# Derive the path where the decrypted file will be stored
out="/var/tmp/nix-import-encrypted/$UID/$new_name"
umask 077
mkdir -p "$(dirname "$out")"

# Decrypt only if necessary
if [[ ! -e $out ]]; then
    agekey=$(sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key || sudo ssh-to-age -private-key -i ~/.ssh/sops)
    SOPS_AGE_KEY="$agekey" sops decrypt --output "$out" "$file"
fi

# Print out path or decrypted content
if [[ $print_out_path == true ]]; then
    echo "$out"
else
    cat "$out"
fi
