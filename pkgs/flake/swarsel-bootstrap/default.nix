{
  name,
  openssh,
  opentofu,
  ssh-to-age,
  writeShellApplication,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    openssh
    (opentofu.withPlugins (p: [ p.hashicorp_local ]))
    ssh-to-age
  ];
  text = ''
    set -eo pipefail

    target_hostname=""
    target_destination=""
    target_arch=""
    target_user="swarsel"
    ssh_port="22"
    persist_dir=""
    disk_encryption=0
    disk_encryption_args=""
    no_disko_deps="false"
    non_interactive="false"
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
      echo "  -a <targeit_arch>                       specify the architecture of the target host."
      echo "                                          target during install process."
      echo
      echo "OPTIONS:"
      echo "  -u <target_user>                        specify target_user with sudo access. nix-config will be cloned to their home."
      echo "                                          Default=''${target_user}."
      echo "  --port <ssh_port>                       specify the ssh port to use for remote access. Default=''${ssh_port}."
      echo "  --debug                                 Enable debug mode."
      echo "  --non-interactive                       Run without prompts (requires FLAKE to be set). Used by the bootstrap test."
      echo "  --no-disko-deps                         Upload only disk script and not dependencies (for use on low ram)."
      echo "  -h | --help                             Print this help."
      exit 0
    }

    function cleanup() {
      rm -rf "$temp"
      rm -rf /tmp/disko-password
    }
    trap cleanup exit

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

    function yes_or_no() {
      echo -en "\x1B[32m[+] $* [y/n] (default: y): \x1B[0m"
      while true; do
        read -rp "" yn
        yn=''${yn:-y}
        case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        esac
      done
    }

    function confirm() {
      local default=$1
      shift
      if [[ $non_interactive == "true" ]]; then
        [[ $default == "y" ]]
        return
      fi
      yes_or_no "$@"
    }

    function update_sops_file() {
      key_name=$1
      key=$2

      tfvars="''${git_root}/tofu/sops/terraform.tfvars"
      if ! grep -qE "^[[:space:]]*''${key_name}[[:space:]]*=[[:space:]]*\"placeholder\"" "$tfvars"; then
        red "No placeholder entry for '$key_name' found in tofu/sops/terraform.tfvars."
        yellow "Add '$key_name = \"placeholder\"' to the hosts map (and a host_configs entry) before bootstrapping."
        exit 1
      fi

      green "Writing age key for $key_name into tofu/sops/terraform.tfvars"
      sed -E -i "s|^([[:space:]]*''${key_name}[[:space:]]*=[[:space:]]*)\"placeholder\"|\1\"''${key}\"|" "$tfvars"

      green "Regenerating .sops.yaml via OpenTofu"
      tofu -chdir="''${git_root}/tofu/sops" init -upgrade -input=false > /dev/null
      tofu -chdir="''${git_root}/tofu/sops" apply -auto-approve
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
      -a)
        shift
        target_arch=$1
        ;;
      -u)
        shift
        target_user=$1
        ;;
      --port)
        shift
        ssh_port=$1
        ;;
      --no-disko-deps)
        no_disko_deps="true"
        ;;
      --non-interactive)
        non_interactive="true"
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

    if [[ $target_arch == "" || $target_destination == "" || $target_hostname == "" ]]; then
      red "error: target_arch, target_destination or target_hostname not set."
      help_and_exit
    fi

    LOCKED="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.node.lockFromBootstrapping)"
    if [[ $LOCKED == "true" ]]; then
      red "THIS SYSTEM IS LOCKED FROM BOOTSTRAPPING - set 'node.lockFromBootstrapping = lib.mkForce false;' to proceed"
      exit
    fi

    green "~SwarselSystems~ remote installer"
    green "Reading system information for $target_hostname ..."

    DISK="$(nix eval --raw ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.rootDisk)"
    green "Root Disk: $DISK"

    CRYPTED="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isCrypted)"
    if [[ $CRYPTED == "true" ]]; then
      green "Encryption: ✓"
      disk_encryption=1
      disk_encryption_args=(
        --disk-encryption-keys
        /tmp/disko-password
        /tmp/disko-password
      )
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

    tty_flag="-t"
    if [[ $non_interactive == "true" ]]; then
      tty_flag=""
    fi
    ssh_cmd="ssh -oport=''${ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $tty_flag $target_user@$target_destination"
    ssh_root_cmd=''${ssh_cmd/''${target_user}@/root@}
    scp_cmd="scp -oport=''${ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

    if [[ -z ''${FLAKE:-} ]]; then
      if [[ $non_interactive == "true" ]]; then
        red "FLAKE must be set in non-interactive mode."
        exit 1
      fi
      FLAKE=/home/"$target_user"/.dotfiles
    fi
    if [ ! -d "$FLAKE" ]; then
      if [[ $non_interactive == "true" ]]; then
        red "FLAKE directory $FLAKE does not exist."
        exit 1
      fi
      cd /home/"$target_user"
      yellow "Flake directory not found - cloning repository from GitHub"
      git clone git@github.com:Swarsel/.dotfiles.git || (yellow "Could not clone repository via SSH - defaulting to HTTPS" && git clone https://github.com/Swarsel/.dotfiles.git)
      FLAKE=/home/"$target_user"/.dotfiles
    fi

    cd "$FLAKE"

    rm files/install/flake.lock || true
    git_root=$(git rev-parse --show-toplevel)
    green "Wiping known_hosts of $target_destination"
    sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts
    green "Preparing a new ssh_host_ed25519_key pair for $target_hostname."
    install -d -m755 "$temp/$persist_dir/etc/ssh"
    ssh-keygen -t ed25519 -f "$temp/$persist_dir/etc/ssh/ssh_host_ed25519_key" -C root@"$target_hostname" -N ""
    chmod 600 "$temp/$persist_dir/etc/ssh/ssh_host_ed25519_key"
    echo "Adding ssh host fingerprint at $target_destination to ~/.ssh/known_hosts"
    ssh-keyscan -p "$ssh_port" "$target_destination" >> ~/.ssh/known_hosts || true
    if [ "$disk_encryption" -eq 1 ]; then
      while true; do
        green "Set disk encryption passphrase:"
        read -rs luks_passphrase
        green "Please confirm passphrase:"
        read -rs luks_passphrase_confirm
        if [[ $luks_passphrase == "$luks_passphrase_confirm" ]]; then
          echo "$luks_passphrase" > /tmp/disko-password
          $ssh_root_cmd "echo '$luks_passphrase' > /tmp/disko-password"
          break
        else
          red "Passwords do not match"
        fi
      done
    fi
    green "Generating hardware-config.nix for $target_hostname and adding it to the nix-config."
    $ssh_root_cmd "nixos-generate-config --force --no-filesystems --root /mnt"

    mkdir -p "$FLAKE"/hosts/nixos/"$target_arch"/"$target_hostname"
    $scp_cmd root@"$target_destination":/mnt/etc/nixos/hardware-configuration.nix "''${git_root}"/hosts/nixos/"$target_arch"/"$target_hostname"/hardware-configuration.nix
    green "Generating hostkey for ssh initrd"
    $ssh_root_cmd "mkdir -p $temp/etc/secrets/initrd /etc/secrets/initrd"
    $ssh_root_cmd "ssh-keygen -t ed25519 -N ''' -f $temp/etc/secrets/initrd/ssh_host_ed25519_key"
    $ssh_root_cmd "cp $temp/etc/secrets/initrd/ssh_host_ed25519_key /etc/secrets/initrd/ssh_host_ed25519_key"

    green "Deploying minimal NixOS installation on $target_destination"

    nixos_anywhere=(nix run github:nix-community/nixos-anywhere/1.10.0 --)
    if [[ -n ''${NIXOS_ANYWHERE:-} ]]; then
      nixos_anywhere=("$NIXOS_ANYWHERE")
    fi

    if [[ $no_disko_deps == "true" ]]; then
      green "Building without disko dependencies (using custom kexec)"
      "''${nixos_anywhere[@]}" "''${disk_encryption_args[@]}" --no-disko-deps --ssh-port "$ssh_port" --extra-files "$temp" --flake ./files/install#"$target_hostname" --kexec "$(nix build --print-out-paths .#packages."$target_arch".swarsel-kexec)/swarsel-kexec-$target_arch.tar.gz" root@"$target_destination"
    else
      green "Building with disko dependencies (using nixos-images kexec)"
      "''${nixos_anywhere[@]}" "''${disk_encryption_args[@]}" --ssh-port "$ssh_port" --extra-files "$temp" --flake ./files/install#"$target_hostname" root@"$target_destination"
    fi

    echo "Updating ssh host fingerprint at $target_destination to ~/.ssh/known_hosts"
    ssh-keyscan -p "$ssh_port" "$target_destination" >> ~/.ssh/known_hosts || true

    if [[ $non_interactive == "true" ]]; then
      green "Waiting for $target_destination to finish booting ..."
      for ((i = 0; i < 120; i++)); do
        if ssh-keyscan -T 5 -p "$ssh_port" "$target_destination" 2> /dev/null | grep -q .; then
          green "$target_destination is booted. Continuing..."
          break
        fi
        sleep 5
      done
    else
      while true; do
        read -rp "Press Enter to continue once the remote host has finished booting."
        if nc -z "$target_destination" "''${ssh_port}" 2> /dev/null; then
          green "$target_destination is booted. Continuing..."
          break
        else
          yellow "$target_destination is not yet ready."
        fi
      done
    fi


    if [[ $SECUREBOOT == "true" ]]; then
      green "Setting up secure boot keys"
      $ssh_root_cmd "mkdir -p /var/lib/sbctl"
      read -ra scp_call <<< "''${scp_cmd}"
      sudo "''${scp_call[@]}" -r /var/lib/sbctl root@"$target_destination":/var/lib/
      $ssh_root_cmd "sbctl enroll-keys --ignore-immutable --microsoft || true"
    fi

    if [ -n "$persist_dir" ] && [[ $non_interactive != "true" ]]; then
      $ssh_root_cmd "cp /etc/machine-id $persist_dir/etc/machine-id || true"
      $ssh_root_cmd "cp -R /etc/ssh/ $persist_dir/etc/ssh/ || true"
    fi
    green "Generating an age key based on the new ssh_host_ed25519_key."
    if [[ $non_interactive == "true" ]]; then
      host_age_key=$(ssh-to-age -i "$temp/$persist_dir/etc/ssh/ssh_host_ed25519_key.pub")
    else
      target_key=$(
        ssh-keyscan -p "$ssh_port" -t ssh-ed25519 "$target_destination" 2>&1 |
          grep ssh-ed25519 |
          cut -f2- -d" " ||
          (
            red "Failed to get ssh key. Host down?"
            exit 1
          )
      )
      host_age_key=$(ssh-to-age <<< "$target_key")
    fi

    if grep -qv '^age1' <<< "$host_age_key"; then
      red "The result from generated age key does not match the expected format."
      yellow "Result: $host_age_key"
      yellow "Expected format: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      exit 1
    else
      echo "$host_age_key"
    fi

    green "Registering $target_hostname in the sops configuration"
    update_sops_file "$target_hostname" "$host_age_key"
    green "Updating all secrets files to reflect updated .sops.yaml"
    sops updatekeys --yes --enable-local-keyservice "''${git_root}"/hosts/nixos/"$target_arch"/"$target_hostname"/secrets/* || true
    if [[ $non_interactive != "true" ]]; then
      green "Making ssh_host_ed25519_key available to home-manager for user $target_user"
      sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts
      $ssh_root_cmd "mkdir -p /home/$target_user/.ssh; chown -R $target_user:users /home/$target_user/.ssh/"
      $scp_cmd root@"$target_destination":/etc/ssh/ssh_host_ed25519_key root@"$target_destination":/home/"$target_user"/.ssh/ssh_host_ed25519_key
      $ssh_root_cmd "chown $target_user:users /home/$target_user/.ssh/ssh_host_ed25519_key"
    fi

    if confirm n "Add ssh host fingerprints for git upstream repositories? (This is needed for building the full config)"; then
      green "Adding ssh host fingerprints for git{lab,hub}"
      $ssh_cmd "mkdir -p /home/$target_user/.ssh/; ssh-keyscan -t ssh-ed25519 gitlab.com github.com | tee /home/$target_user/.ssh/known_hosts"
      $ssh_root_cmd "mkdir -p /root/.ssh/; ssh-keyscan -t ssh-ed25519 gitlab.com github.com | tee /root/.ssh/known_hosts"
    fi

    if confirm n "Do you want to copy your full nix-config and nix-secrets to $target_hostname?"; then
      green "Adding ssh host fingerprint at $target_destination to ~/.ssh/known_hosts"
      ssh-keyscan -p "$ssh_port" "$target_destination" >> ~/.ssh/known_hosts || true
      green "Copying full nix-config to $target_hostname"
      cd "''${git_root}"
      just sync "$target_user" "$target_destination"

      if [ -n "$persist_dir" ]; then
        $ssh_root_cmd "cp -r /home/$target_user/.dotfiles $persist_dir/.dotfiles || true"
        $ssh_root_cmd "cp -r /home/$target_user/.ssh $persist_dir/.ssh || true"
      fi

      if confirm n "Do you want to rebuild immediately?"; then
        green "Building nix-config for $target_hostname"
        store_path=$(nix build --no-link --print-out-paths .#nixosConfigurations."$target_hostname".config.system.build.toplevel)
        green "Copying generation to $target_hostname"
        nix copy --to "ssh://root@$target_destination" "$store_path"
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
        echo "sudo nixos-rebuild --show-trace --flake .#$target_hostname switch"
        echo
      fi
    fi

    green "NixOS was successfully installed!"
    if confirm n "You can now commit the nix-config, which includes the hardware-configuration.nix for $target_hostname?"; then
      cd "''${git_root}"
      deadnix hosts/nixos/"$target_arch"/"$target_hostname"/hardware-configuration.nix -qe
      nixfmt hosts/nixos/"$target_arch"/"$target_hostname"/hardware-configuration.nix
      (pre-commit run --all-files 2> /dev/null || true) || true
      git add "$(realpath "$git_root/hosts/nixos/$target_arch/$target_hostname")/hardware-configuration.nix"
      git add "$git_root/.sops.yaml"
      git add "$git_root/tofu/sops/terraform.tfvars"
      git add "$git_root/secrets" 2> /dev/null || true
      git add "$(realpath "$git_root/hosts/nixos/$target_arch/$target_hostname")/secrets" 2> /dev/null || true
      git commit -m "feat: deployed $target_hostname" || true
      if confirm n "Push the committed changes to the remote?"; then
        git push
      fi
    fi

    if confirm n "Reboot now?"; then
      $ssh_root_cmd "reboot"
    fi

    rm -rf /tmp/disko-password
  '';
}
