# highly inspired by https://github.com/EmergentMind/nix-config/blob/dev/files/scripts/bootstrap-nixos.sh
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
    echo "Remotely installs SwarselSystem on a target machine including secret deployment."
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

green "~SwarselSystems~ remote installer"
green "Reading system information for $target_hostname ..."

DISK="$(nix eval --raw ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.rootDisk)"
green "Root Disk: $DISK"

CRYPTED="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isCrypted)"
if [[ $CRYPTED == "true" ]]; then
    green "Encryption: ✓"
    disk_encryption=1
else
    red "Encryption: X"
    disk_encryption=0
fi

IMPERMANENCE="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isImpermanence)"
if [[ $IMPERMANENCE == "true" ]]; then
    green "Impermanence: ✓"
    persist_dir="/persist"
else
    red "Impermanence: X"
    persist_dir=""
fi

SWAP="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isSwap)"
if [[ $SWAP == "true" ]]; then
    green "Swap: ✓"
else
    red "Swap: X"
fi

SECUREBOOT="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isSecureBoot)"
if [[ $SECUREBOOT == "true" ]]; then
    green "Secure Boot: ✓"
else
    red "Secure Boot: X"
fi

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
rm install/flake.lock || true
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
    while true; do
        green "Set disk encryption passphrase:"
        read -rs luks_passphrase
        green "Please confirm passphrase:"
        read -rs luks_passphrase_confirm
        if [[ $luks_passphrase == "$luks_passphrase_confirm" ]]; then
            $ssh_root_cmd "/bin/sh -c 'echo $luks_passphrase > /tmp/disko-password'"
            break
        else
            red "Passwords do not match"
        fi
    done
fi
# ------------------------
green "Generating hardware-config.nix for $target_hostname and adding it to the nix-config."
$ssh_root_cmd "nixos-generate-config --force --no-filesystems --root /mnt"

green "Injecting initialSetup"
$ssh_root_cmd "sed -i '/  boot.extraModulePackages /a \  swarselsystems.initialSetup = true;' /mnt/etc/nixos/hardware-configuration.nix"

mkdir -p "$FLAKE"/hosts/nixos/"$target_hostname"
$scp_cmd root@"$target_destination":/mnt/etc/nixos/hardware-configuration.nix "${git_root}"/hosts/nixos/"$target_hostname"/hardware-configuration.nix
# ------------------------

green "Deploying minimal NixOS installation on $target_destination"
nix run github:nix-community/nixos-anywhere/1.10.0 -- --ssh-port "$ssh_port" --extra-files "$temp" --flake ./install#"$target_hostname" root@"$target_destination"

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

if [[ $SECUREBOOT == "true" ]]; then
    green "Setting up secure boot keys"
    $ssh_root_cmd "mkdir -p /var/lib/sbctl"
    read -ra scp_call <<< "${scp_cmd}"
    sudo "${scp_call[@]}" -r /var/lib/sbctl root@"$target_destination":/var/lib/
    $ssh_root_cmd "sbctl enroll-keys --ignore-immutable --microsoft || true"
fi
# ------------------------
green "Disabling initialSetup"
sed -i '/swarselsystems\.initialSetup = true;/d' "$git_root"/hosts/nixos/"$target_hostname"/hardware-configuration.nix

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
sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts
$ssh_root_cmd "mkdir -p /home/$target_user/.ssh; chown -R $target_user:users /home/$target_user/.ssh/"
$scp_cmd root@"$target_destination":/etc/ssh/ssh_host_ed25519_key root@"$target_destination":/home/"$target_user"/.ssh/ssh_host_ed25519_key
$ssh_root_cmd "chown $target_user:users /home/$target_user/.ssh/ssh_host_ed25519_key"
# __________________________

if yes_or_no "Add ssh host fingerprints for git upstream repositories? (This is needed for building the full config)"; then
    green "Adding ssh host fingerprints for git{lab,hub}"
    $ssh_cmd "mkdir -p /home/$target_user/.ssh/; ssh-keyscan -t ssh-ed25519 gitlab.com github.com swagit.swarsel.win | tee /home/$target_user/.ssh/known_hosts"
    $ssh_root_cmd "mkdir -p /root/.ssh/; ssh-keyscan -t ssh-ed25519 gitlab.com github.com swagit.swarsel.win | tee /root/.ssh/known_hosts"
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
        $ssh_root_cmd "cp -r /home/$target_user/.ssh $persist_dir/.ssh || true"
    fi

    if yes_or_no "Do you want to rebuild immediately?"; then
        green "Building nix-config for $target_hostname"
        # yellow "Reminder: The password is 'setup'"
        $ssh_root_cmd "mkdir -p /root/.local/share/nix/; printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' | tee /root/.local/share/nix/trusted-settings.json"
        # $ssh_cmd -oForwardAgent=yes "cd .dotfiles && sudo nixos-rebuild --show-trace --flake .#$target_hostname switch"
        store_path=$(nix build --no-link --print-out-paths .#nixosConfigurations."$target_hostname".config.system.build.toplevel)
        green "Copying generation to $target_hostname"
        nix copy --to "ssh://root@$target_destination" "$store_path"
        # prev_system=$($ssh_root_cmd " readlink -e /nix/var/nix/profiles/system")
        green "Linking generation in bootloader"
        $ssh_root_cmd "/run/current-system/sw/bin/nix-env --profile /nix/var/nix/profiles/system --set $store_path"
        green "Setting generation to activate upon next boot"
        $ssh_root_cmd "$store_path/bin/switch-to-configuration boot"
    else
        echo
        green "NixOS was successfully installed!"
        echo "Post-install config build instructions:"
        echo "To copy nix-config from this machine to the $target_hostname, run the following command from ~/nix-config"
        echo "just sync $target_user $target_destination"
        echo "To rebuild, sign into $target_hostname and run the following command from ~/nix-config"
        echo "cd nix-config"
        # see above FIXME:(bootstrap)
        echo "sudo nixos-rebuild .pre-commit-config.yaml show-trace --flake .#$target_hostname switch"
        # echo "just rebuild"
        echo
    fi
fi

green "NixOS was successfully installed!"
if yes_or_no "You can now commit and push the nix-config, which includes the hardware-configuration.nix for $target_hostname?"; then
    cd "${git_root}"
    deadnix hosts/nixos/"$target_hostname"/hardware-configuration.nix -qe
    nixpkgs--fmt hosts/nixos/"$target_hostname"/hardware-configuration.nix
    (.pre-commit-config.yaml mit run --all-files 2> /dev/null || true) &&
        git add "$git_root/hosts/nixos/$target_hostname/hardware-configuration.nix" &&
        git add "$git_root/.sops.yaml" &&
        git add "$git_root/secrets" &&
        (git commit -m "feat: deployed $target_hostname" || true) && git push
fi

if yes_or_no "Reboot now?"; then
    $ssh_root_cmd "reboot"
fi
