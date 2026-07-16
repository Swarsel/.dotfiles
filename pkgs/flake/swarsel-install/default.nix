{
  name,
  writeShellApplication,
  git,
  jq,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    git
    jq
  ];
  text = ''
    set -eo pipefail

    export NIX_CONFIG="experimental-features = nix-command flakes"

    target_config="hotel"
    target_user="swarsel"
    target_arch="$(uname -m)-linux"
    target_disk=""
    target_repo="https://github.com/Swarsel/.dotfiles.git"
    persist_dir=""
    skip_hardware_config=0
    demo_flags=()

    function help_and_exit() {
      echo
      echo "Locally installs SwarselSystem on this machine."
      echo
      echo "USAGE: $0 [OPTIONS]"
      echo
      echo "ARGS:"
      echo "  -n <target_config>                      specify the nixos config to deploy."
      echo "                                          Default: hotel"
      echo "  -u <target_user>                        specify user to deploy for."
      echo "                                          Default: swarsel"
      echo "  -a <target_arch>                        specify target architecture."
      echo "                                          Default: $(uname -m)-linux"
      echo "  -d <target_disk>                        verify that the config installs to this disk."
      echo "  -r <target_repo>                        specify repository to clone."
      echo "                                          Default: https://github.com/Swarsel/.dotfiles.git"
      echo "  -H                                      keep the hardware configuration from the repository."
      echo "  -h | --help                             Print this help."
      exit 0
    }

    function red() {
      echo -e "\x1B[31m[!] $1 \x1B[0m"
      if [ -n "''${2-}" ]; then
        echo -e "\x1B[31m[!] $($2) \x1B[0m"
      fi
    }
    function green() {
      echo -e "\x1B[32m[+] $1 \x1B[0m"
      if [ -n "''${2-}" ]; then
        echo -e "\x1B[32m[+] $($2) \x1B[0m"
      fi
    }
    function yellow() {
      echo -e "\x1B[33m[*] $1 \x1B[0m"
      if [ -n "''${2-}" ]; then
        echo -e "\x1B[33m[*] $($2) \x1B[0m"
      fi
    }

    while [[ $# -gt 0 ]]; do
      case "$1" in
      -n)
        shift
        target_config=$1
        ;;
      -u)
        shift
        target_user=$1
        ;;
      -a)
        shift
        target_arch=$1
        ;;
      -d)
        shift
        target_disk=$1
        ;;
      -r)
        shift
        target_repo=$1
        ;;
      -H) skip_hardware_config=1 ;;
      -h | --help) help_and_exit ;;
      *)
        echo "Invalid option detected."
        help_and_exit
        ;;
      esac
      shift
    done

    function cleanup() {
      sudo rm -rf /root/.cache/nix "/home/$target_user/.cache/nix"
    }
    trap cleanup exit

    green "~SwarselSystems~ local installer"

    cd /home/"$target_user"

    sudo rm -rf /root/.cache/nix .cache/nix .dotfiles

    green "Cloning repository from $target_repo"
    git clone "$target_repo" .dotfiles
    cd .dotfiles

    local_keys=$(ssh-add -L || true)
    pub_key=$(cat files/public/ssh/yubikey.pub)
    read -ra pub_arr <<< "$pub_key"

    if [[ $local_keys != *"''${pub_arr[1]}"* ]]; then
      yellow "The ssh key for this configuration is not available."
      green "Overriding private inputs so that the configuration is buildable ..."
      demo_flags=(--override-input vbc-nix "path:$PWD/files/stub" --override-input repoSecrets "path:$PWD/hosts/utility/hotel/secrets" --no-write-lock-file)
    else
      green "Valid SSH key found! Continuing with installation"
    fi

    target_attr="$target_config"
    if [[ $target_arch != "x86_64-linux" ]] && [[ $(nix eval "''${demo_flags[@]}" .#nixosConfigurationsMinimal --apply "c: c ? \"$target_config-$target_arch\"" 2> /dev/null) == "true" ]]; then
      target_attr="$target_config-$target_arch"
      green "Using arch-specific configuration $target_attr"
    fi

    green "Reading system information for $target_attr ..."
    settings=$(nix eval "''${demo_flags[@]}" --json .#nixosConfigurationsMinimal."$target_attr".config.swarselsystems --apply 'c: { inherit (c) rootDisk isCrypted isImpermanence isSwap isSecureBoot; }')

    DISK=$(jq -r .rootDisk <<< "$settings")
    green "Root Disk in config: $DISK"
    if [[ -n $target_disk && $target_disk != "$DISK" ]]; then
      red "error: this configuration installs to $DISK, but -d $target_disk was passed."
      red "Adjust swarselsystems.rootDisk in hosts/nixos/$target_arch/$target_config or omit -d."
      exit 1
    fi

    CRYPTED=$(jq -r .isCrypted <<< "$settings")
    if [[ $CRYPTED == "true" ]]; then
      green "Encryption: ✓"
    else
      red "Encryption: X"
    fi

    IMPERMANENCE=$(jq -r .isImpermanence <<< "$settings")
    if [[ $IMPERMANENCE == "true" ]]; then
      green "Impermanence: ✓"
      persist_dir="/persist"
    else
      red "Impermanence: X"
    fi

    SWAP=$(jq -r .isSwap <<< "$settings")
    if [[ $SWAP == "true" ]]; then
      green "Swap: ✓"
    else
      red "Swap: X"
    fi

    SECUREBOOT=$(jq -r .isSecureBoot <<< "$settings")
    if [[ $SECUREBOOT == "true" ]]; then
      green "Secure Boot: ✓"
    else
      red "Secure Boot: X"
    fi

    if [[ $CRYPTED == "true" ]]; then
      if [ -f /tmp/disko-password ]; then
        yellow "Using existing passphrase from /tmp/disko-password"
      else
        while true; do
          green "Set disk encryption passphrase:"
          read -rs luks_passphrase
          green "Please confirm passphrase:"
          read -rs luks_passphrase_confirm
          if [[ $luks_passphrase == "$luks_passphrase_confirm" ]]; then
            echo "$luks_passphrase" > /tmp/disko-password
            break
          else
            red "Passwords do not match"
          fi
        done
      fi
    fi

    green "Setting up disk ..."
    disko_script=$(nix build "''${demo_flags[@]}" --no-link --print-out-paths .#nixosConfigurationsMinimal."$target_attr".config.system.build.destroyFormatMount)
    sudo "$disko_script"/bin/disko-destroy-format-mount --yes-wipe-all-disks

    if [[ $skip_hardware_config -eq 1 ]]; then
      yellow "Keeping hardware configuration from the repository"
    else
      green "Generating hardware configuration ..."
      sudo nixos-generate-config --root /mnt --no-filesystems --dir /home/"$target_user"/.dotfiles/hosts/nixos/"$target_arch"/"$target_config"/
      git add "$(realpath --relative-to=. hosts/nixos/"$target_arch"/"$target_config")"/hardware-configuration.nix
    fi

    green "Building flake $target_config ..."
    store_path=$(nix build "''${demo_flags[@]}" --no-link --print-out-paths .#nixosConfigurationsMinimal."$target_attr".config.system.build.toplevel)

    green "Copying configuration to target ..."
    sudo mkdir -p /mnt"$persist_dir"/home/"$target_user"/
    sudo cp -r /home/"$target_user"/.dotfiles /mnt"$persist_dir"/home/"$target_user"/
    sudo chown -R 1000:100 /mnt"$persist_dir"/home/"$target_user"

    green "Installing flake $target_config ..."
    sudo nixos-install --no-root-passwd --no-channel-copy --system "$store_path"
    green "Installation finished! Reboot to see changes"
    yellow "Please keep in mind that this is only a demo of the configuration. Things might break unexpectedly."
  '';
}
