# highly inspired by https://github.com/EmergentMind/nix-config/blob/dev/scripts/bootstrap-nixos.sh
set -eo pipefail

target_hostname=""
target_destination=""
target_user="swarsel"
ssh_port="22"
persist_dir=""
disk_encryption=0
temp=$(mktemp -d)

function help_and_exit() {
    echo
    echo "Remotely installs NixOS on a target machine using this nix-config."
    echo
    echo "USAGE: $0 -n <target_hostname> -d <target_destination> [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  -n <target_hostname>                    specify target_hostname of the target host to deploy the nixos config on."
    echo "  -d <target_destination>                 specify ip or url to the target host."
    echo "                                          target during install process."
    echo
    echo "OPTIONS:"
    echo "  -u <target_user>                        specify target_user with sudo access. nix-config will be cloned to their home."
    echo "                                          Default='${target_user}'."
    echo "  --port <ssh_port>                       specify the ssh port to use for remote access. Default=${ssh_port}."
    echo "  --impermanence                          Use this flag if the target machine has impermanence enabled. WARNING: Assumes /persist path."
    echo "  --encryption                            Use this flag if the target machine has full disk encryption enabled."
    echo "  --debug                                 Enable debug mode."
    echo "  -h | --help                             Print this help."
    exit 0
}

function cleanup() {
    rm -rf "$temp"
}
trap cleanup exit

function red() {
    echo -e "\x1B[31m[!] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[31m[!] $($2) \x1B[0m"
    fi
}
function green() {
    echo -e "\x1B[32m[+] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[32m[+] $($2) \x1B[0m"
    fi
}
function yellow() {
    echo -e "\x1B[33m[*] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[33m[*] $($2) \x1B[0m"
    fi
}

function yes_or_no() {
    echo -en "\x1B[32m[+] $* [y/n] (default: y): \x1B[0m"
    while true; do
        read -rp "" yn
        yn=${yn:-y}
        case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        esac
    done
}

function update_sops_file() {
    key_name=$1
    key_type=$2
    key=$3

    if [ ! "$key_type" == "hosts" ] && [ ! "$key_type" == "users" ]; then
        red "Invalid key type passed to update_sops_file. Must be either 'hosts' or 'users'."
        exit 1
    fi
    cd "${git_root}"

    SOPS_FILE=".sops.yaml"
    sed -i "{
                              # Remove any * and & entries for this host
                              /[*&]$key_name/ d;
                              # Inject a new age: entry
                              # n matches the first line following age: and p prints it, then we transform it while reusing the spacing
                              /age:/{n; p; s/\(.*- \*\).*/\1$key_name/};
                              # Inject a new hosts or user: entry
                              /&$key_type/{n; p; s/\(.*- &\).*/\1$key_name $key/}
                              }" $SOPS_FILE
    green "Updating .sops.yaml"
    cd -
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -n)
        shift
        target_hostname=$1
        ;;
    -d)
        shift
        target_destination=$1
        ;;
    -u)
        shift
        target_user=$1
        ;;
    --port)
        shift
        ssh_port=$1
        ;;
    --temp-override)
        shift
        temp=$1
        ;;
    --impermanence)
        shift
        persist_dir="/persist"
        ;;
    --encryption)
        shift
        disk_encryption=1
        ;;
    --debug)
        set -x
        ;;
    -h | --help) help_and_exit ;;
    *)
        echo "Invalid option detected."
        help_and_exit
        ;;
    esac
    shift
done

ssh_cmd="ssh -oport=${ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t $target_user@$target_destination"
# ssh_root_cmd=$(echo "$ssh_cmd" | sed "s|${target_user}@|root@|") # uses @ in the sed switch to avoid it triggering on the $ssh_key value
ssh_root_cmd=${ssh_cmd/${target_user}@/root@}
scp_cmd="scp -oport=${ssh_port} -o StrictHostKeyChecking=no"

if [[ -z ${FLAKE} ]]; then
    FLAKE=/home/"$target_user"/.dotfiles
fi
if [ ! -d "$FLAKE" ]; then
    cd /home/"$target_user"
    yellow "Flake directory not found - cloning repository from GitHub"
    git clone git@github.com:Swarsel/.dotfiles.git || (yellow "Could not clone repository via SSH - defaulting to HTTPS" && git clone https://github.com/Swarsel/.dotfiles.git)
    FLAKE=/home/"$target_user"/.dotfiles
fi

cd "$FLAKE"
git_root=$(git rev-parse --show-toplevel)
# ------------------------
green "Wiping known_hosts of $target_destination"
sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts
# ------------------------
green "Preparing a new ssh_host_ed25519_key pair for $target_hostname."
# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/$persist_dir/etc/ssh"
# Generate host ssh key pair without a passphrase
ssh-keygen -t ed25519 -f "$temp/$persist_dir/etc/ssh/ssh_host_ed25519_key" -C root@"$target_hostname" -N ""
# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/$persist_dir/etc/ssh/ssh_host_ed25519_key"
echo "Adding ssh host fingerprint at $target_destination to ~/.ssh/known_hosts"
# This will fail if we already know the host, but that's fine
ssh-keyscan -p "$ssh_port" "$target_destination" >> ~/.ssh/known_hosts || true
# ------------------------
# when using luks, disko expects a passphrase on /tmp/disko-password, so we set it for now and will update the passphrase later
# via the config
if [ "$disk_encryption" -eq 1 ]; then
    green "--encryption set: Preparing a temporary password for disko."
    green "[Optional] Set disk encryption passphrase:"
    read -rs luks_passphrase
    if [ -n "$luks_passphrase" ]; then
        $ssh_root_cmd "/bin/sh -c 'echo $luks_passphrase > /tmp/disko-password'"
    else
        $ssh_root_cmd "/bin/sh -c 'echo passphrase > /tmp/disko-password'"
    fi
else
    green "--encryption not set: Not using disk encryption.."
fi
# ------------------------
green "Generating hardware-config.nix for $target_hostname and adding it to the nix-config."
$ssh_root_cmd "nixos-generate-config --force --no-filesystems --root /mnt"
mkdir -p "$FLAKE"/hosts/nixos/"$target_hostname"
$scp_cmd root@"$target_destination":/mnt/etc/nixos/hardware-configuration.nix "${git_root}"/hosts/nixos/"$target_hostname"/hardware-configuration.nix
# ------------------------
green "Deploying minimal NixOS installation on $target_destination"
SHELL=/bin/sh nix run github:nix-community/nixos-anywhere -- --ssh-port "$ssh_port" --extra-files "$temp" --flake .#"$target_hostname" root@"$target_destination"

echo "Updating ssh host fingerprint at $target_destination to ~/.ssh/known_hosts"
ssh-keyscan -p "$ssh_port" "$target_destination" >> ~/.ssh/known_hosts || true
# ------------------------

while true; do
    read -rp "Press Enter to continue once the remote host has finished booting."
    if nc -z "$target_destination" "${ssh_port}" 2> /dev/null; then
        green "$target_destination is booted. Continuing..."
        break
    else
        yellow "$target_destination is not yet ready."
    fi
done
# ------------------------
if [ -n "$persist_dir" ]; then
    $ssh_root_cmd "cp /etc/machine-id $persist_dir/etc/machine-id || true"
    $ssh_root_cmd "cp -R /etc/ssh/ $persist_dir/etc/ssh/ || true"
fi
# ------------------------
green "Generating an age key based on the new ssh_host_ed25519_key."
target_key=$(
    ssh-keyscan -p "$ssh_port" -t ssh-ed25519 "$target_destination" 2>&1 |
        grep ssh-ed25519 |
        cut -f2- -d" " ||
        (
            red "Failed to get ssh key. Host down?"
            exit 1
        )
)
host_age_key=$(nix shell nixpkgs#ssh-to-age.out -c sh -c "echo $target_key | ssh-to-age")

if grep -qv '^age1' <<< "$host_age_key"; then
    red "The result from generated age key does not match the expected format."
    yellow "Result: $host_age_key"
    yellow "Expected format: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    exit 1
else
    echo "$host_age_key"
fi

green "Updating nix-secrets/.sops.yaml"
update_sops_file "$target_hostname" "hosts" "$host_age_key"
yellow ".sops.yaml has been updated. There may be superfluous entries, you might need to edit manually."
if yes_or_no "Do you want to manually edit .sops.yaml now?"; then
    vim "${git_root}"/.sops.yaml
fi
green "Updating all secrets files to reflect updates .sops.yaml"
sops updatekeys --yes --enable-local-keyservice "${git_root}"/secrets/*/secrets.yaml
# --------------------------
green "Making ssh_host_ed25519_key available to home-manager for user $target_user"
$scp_cmd root@"$target_destination":/etc/ssh/ssh_host_ed25519_key root@"$target_destination":/home/"$target_user"/.ssh/ssh_host_ed25519_key
$ssh_root_cmd "chown $target_user:users /home/swarsel/.ssh/ssh_host_ed25519_key"
# __________________________

if yes_or_no "Add ssh host fingerprints for git upstream repositories? (This is needed for building the full config)"; then
    green "Adding ssh host fingerprints for git{lab,hub}"
    $ssh_cmd "mkdir -p /home/$target_user/.ssh/; ssh-keyscan -t ssh-ed25519 gitlab.com github.com swagit.swarsel.win >> /home/$target_user/.ssh/known_hosts"
    $ssh_root_cmd "mkdir -p /root/.ssh/; ssh-keyscan -t ssh-ed25519 gitlab.com github.com swagit.swarsel.win >> /root/.ssh/known_hosts"
fi
# --------------------------

if yes_or_no "Do you want to copy your full nix-config and nix-secrets to $target_hostname?"; then
    green "Adding ssh host fingerprint at $target_destination to ~/.ssh/known_hosts"
    ssh-keyscan -p "$ssh_port" "$target_destination" >> ~/.ssh/known_hosts || true
    green "Copying full nix-config to $target_hostname"
    cd "${git_root}"
    just sync "$target_user" "$target_destination"

    if [ -n "$persist_dir" ]; then
        $ssh_root_cmd "cp -r /home/$target_user/.dotfiles $persist_dir/.dotfiles || true"
    fi

    if yes_or_no "Do you want to rebuild immediately?"; then
        green "Rebuilding nix-config on $target_hostname"
        $ssh_root_cmd "mkdir -p /root/.local/share/nix/; printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' > /root/.local/share/nix/trusted-settings.json"
        $ssh_cmd -oForwardAgent=yes "cd .dotfiles && sudo nixos-rebuild --show-trace --flake .#$target_hostname switch"
    fi
else
    echo
    green "NixOS was successfully installed!"
    echo "Post-install config build instructions:"
    echo "To copy nix-config from this machine to the $target_hostname, run the following command from ~/nix-config"
    echo "just sync $target_user $target_destination"
    echo "To rebuild, sign into $target_hostname and run the following command from ~/nix-config"
    echo "cd nix-config"
    # see above FIXME:(bootstrap)
    echo "sudo nixos-rebuild --show-trace --flake .#$target_hostname switch"
    # echo "just rebuild"
    echo
fi

if yes_or_no "You can now commit and push the nix-config, which includes the hardware-configuration.nix for $target_hostname?"; then
    cd "${git_root}"
    deadnix hosts/nixos/"$target_hostname"/hardware-configuration.nix -qe
    nixpkgs-fmt hosts/nixos/"$target_hostname"/hardware-configuration.nix
    (pre-commit run --all-files 2> /dev/null || true) &&
        git add "$git_root/hosts/nixos/$target_hostname/hardware-configuration.nix" &&
        git add "$git_root/.sops.yaml" &&
        git add "$git_root/secrets" &&
        (git commit -m "feat: deployed $target_hostname" || true) && git push
fi
