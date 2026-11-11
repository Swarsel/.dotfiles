{
  name,
  git,
  nixos-anywhere,
  openssh,
  opentofu,
  sops,
  ssh-to-age,
  writeShellApplication,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    git
    nixos-anywhere
    openssh
    (opentofu.withPlugins (p: [ p.hashicorp_local ]))
    sops
    ssh-to-age
  ];
  text = ''
    usage() {
      echo "usage: ${name} [-p ssh-port] [-k] <host> <destination>" >&2
      exit 1
    }

    port=22
    kexec=0
    while getopts :p:k opt; do
      case $opt in
      p) port=$OPTARG ;;
      k) kexec=1 ;;
      *) usage ;;
      esac
    done
    shift $((OPTIND - 1))
    if [[ $# -ne 2 ]]; then
      usage
    fi
    host=$1
    destination=$2

    cd "''${FLAKE:-.}"

    settings=$(nix eval --raw ".#nixosConfigurations.$host.config" --apply 'c: let flag = b: if b then "1" else "0"; in toString [ c.nixpkgs.hostPlatform.system (flag c.node.lockFromBootstrapping) (flag c.swarselsystems.isCrypted) (flag c.swarselsystems.isSecureBoot) (if c.swarselsystems.isImpermanence then "/persist" else "") ]')
    read -r system locked crypted secureboot persist <<<"$settings"
    if [[ $locked -eq 1 ]]; then
      echo "$host is locked from bootstrapping, set node.lockFromBootstrapping = lib.mkForce false to proceed" >&2
      exit 1
    fi

    temp=$(mktemp -d)
    trap 'rm -rf "$temp"' EXIT
    files=$temp/files
    args=(--ssh-port "$port" --extra-files "$files")

    mkdir -p "$files$persist/etc/ssh"
    ssh-keygen -q -t ed25519 -N "" -C "root@$host" -f "$files$persist/etc/ssh/ssh_host_ed25519_key"
    if [[ -n $persist ]]; then
      systemd-id128 new > "$files$persist/etc/machine-id"
    fi

    if [[ $crypted -eq 1 ]]; then
      mkdir -p "$files$persist/etc/secrets/initrd"
      ssh-keygen -q -t ed25519 -N "" -f "$files$persist/etc/secrets/initrd/ssh_host_ed25519_key"
      read -rsp "Disk encryption passphrase: " passphrase
      echo
      read -rsp "Repeat passphrase: " repeat
      echo
      if [[ $passphrase != "$repeat" ]]; then
        echo "passphrases do not match" >&2
        exit 1
      fi
      echo "$passphrase" > "$temp/disko-password"
      args+=(--disk-encryption-keys /tmp/disko-password "$temp/disko-password")
    fi

    if [[ $secureboot -eq 1 ]]; then
      mkdir -p "$files$persist/var/lib"
      sudo tar -C /var/lib -c sbctl | tar -C "$files$persist/var/lib" -x
    fi

    if [[ $kexec -eq 1 ]]; then
      args+=(--no-disko-deps --kexec "$(nix build --no-link --print-out-paths ".#packages.$system.swarsel-kexec")/swarsel-kexec-$system.tar.gz")
    fi

    hardware_config=hosts/nixos/$system/$host/hardware-configuration.nix
    mkdir -p "$(dirname "$hardware_config")"
    rm -f files/install/flake.lock
    ssh-keygen -R "$host" &>/dev/null || true
    ssh-keygen -R "$destination" &>/dev/null || true
    nixos-anywhere "''${args[@]}" --generate-hardware-config nixos-generate-config "$hardware_config" --flake "./files/install#$host" "root@$destination"
    nix fmt -- "$hardware_config"

    ssh-to-age -i "$files$persist/etc/ssh/ssh_host_ed25519_key.pub" > "files/public/age/hosts/$host.pub"
    tofu -chdir=tofu/sops init -upgrade -input=false >/dev/null
    tofu -chdir=tofu/sops apply -auto-approve
    eval_secrets=("hosts/nixos/$system/$host"/secrets/*.enc)
    if [[ -e ''${eval_secrets[0]} ]]; then
      sops updatekeys --yes --enable-local-keyservice "''${eval_secrets[@]}"
    fi
    nix run .#sops-rekey -- --add-to-git rekey
    git add "$hardware_config" .sops.yaml "files/public/age/hosts/$host.pub"

    if [[ $secureboot -eq 1 ]]; then
      echo "put the firmware of $host into setup mode and run: sbctl enroll-keys --ignore-immutable --microsoft"
    fi
  '';
}
