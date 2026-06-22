{ self, ... }:
{
  perSystem =
    {
      lib,
      system,
      pkgs,
      ...
    }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.bootstrap-install-test = pkgs.writeShellApplication {
        name = "bootstrap-install-test";
        runtimeInputs = [
          pkgs.openssh
          pkgs.sops
          pkgs.ssh-to-age
          pkgs.gnupg
          pkgs.git
          pkgs.rsync
          pkgs.gawk
          pkgs.coreutils
          pkgs.qemu
          pkgs.socat
          self.packages.${system}.swarsel-bootstrap
        ];
        text = ''
          set -euo pipefail

          target_config="toto"
          target_arch="x86_64-linux"
          ssh_port="2222"
          secret_key="toto-deploy-test"
          secret_plaintext="bootstrap-secret-deployment-ok"

          iso_file=$(echo ${self.packages.${system}.live-iso}/iso/*.iso)
          ovmf=${pkgs.OVMF.fd}/FV

          repo=$(git rev-parse --show-toplevel)
          tmp=$(mktemp -d /tmp/bootstrap-test.XXXXXX)
          work="$tmp/dotfiles"
          disk="$tmp/$target_config.qcow2"
          ovmf_vars="$tmp/OVMF_VARS.fd"
          qemu_pid=""
          eject_watcher_pid=""

          ssh_config="$HOME/.ssh/config"
          ssh_config_managed=""
          ssh_config_restore=""
          function cleanup() {
              [[ -n $eject_watcher_pid ]] && kill "$eject_watcher_pid" 2> /dev/null || true
              [[ -n $qemu_pid ]] && kill "$qemu_pid" 2> /dev/null || true
              if [[ -n $ssh_config_managed ]]; then
                  rm -f "$ssh_config"
                  [[ -n $ssh_config_restore ]] && cp -P "$tmp/ssh_config.bak" "$ssh_config"
              fi
              rm -rf "$tmp"
          }
          trap cleanup EXIT

          gpg_ssh_sock=$(gpgconf --list-dirs agent-ssh-socket 2> /dev/null || true)
          [[ -n $gpg_ssh_sock ]] && export SSH_AUTH_SOCK="$gpg_ssh_sock"

          if [[ -L $ssh_config || -e $ssh_config ]]; then
              cp -P "$ssh_config" "$tmp/ssh_config.bak"
              ssh_config_restore=1
          fi
          mkdir -p "$HOME/.ssh"
          rm -f "$ssh_config"
          cat > "$ssh_config" << EOF
          Host *
              ControlMaster auto
              ControlPath $tmp/cm-%r@%h-%p
              ControlPersist 600
              ServerAliveInterval 5
              ServerAliveCountMax 2
          EOF
          chmod 600 "$ssh_config"
          ssh_config_managed=1

          function banner_up() {
              timeout 3 bash -c "exec 3<> /dev/tcp/127.0.0.1/$ssh_port; head -c 4 <&3" 2> /dev/null | grep -q SSH
          }

          echo "[*] Preparing isolated clone in $work"
          mkdir -p "$work"
          rsync -a --filter=':- .gitignore' --exclude=.git "$repo"/ "$work"/
          git -C "$work" init -q -b main
          git -C "$work" add -A
          git -C "$work" -c user.email=test@example.org -c user.name=test -c commit.gpgsign=false commit -q --no-verify -m "bootstrap-test base"

          echo "[*] Creating blank target disk"
          cp "$ovmf/OVMF_VARS.fd" "$ovmf_vars"
          chmod u+w "$ovmf_vars"
          qemu-img create -f qcow2 "$disk" 32G > /dev/null

          echo "[*] Booting target VM (installer first boot, installed disk afterwards)"
          qemu-system-x86_64 \
              -enable-kvm -m 8192 -smp 4 \
              -drive if=pflash,format=raw,readonly=on,file="$ovmf/OVMF_CODE.fd" \
              -drive if=pflash,format=raw,file="$ovmf_vars" \
              -drive id=hd0,file="$disk",if=none,format=qcow2 \
              -device virtio-blk-pci,drive=hd0,bootindex=1 \
              -drive id=cd0,file="$iso_file",if=none,media=cdrom \
              -device ide-cd,drive=cd0,id=cdrom0,bootindex=2 \
              -boot menu=off \
              -netdev "user,id=net0,hostfwd=tcp::$ssh_port-:22" -device virtio-net,netdev=net0 \
              -qmp "unix:$tmp/qmp.sock,server=on,wait=off" \
              -display none -serial "file:$tmp/console.log" &
          qemu_pid=$!

          (
              until banner_up; do sleep 1; done
              while banner_up; do sleep 2; done
              printf '%s\n' \
                  '{"execute":"qmp_capabilities"}' \
                  '{"execute":"eject","arguments":{"id":"cdrom0","force":true}}' |
                  socat - "UNIX-CONNECT:$tmp/qmp.sock" > /dev/null 2>&1 || true
          ) &
          eject_watcher_pid=$!

          echo "[*] Waiting for installer SSH on port $ssh_port"
          for ((i = 0; i < 120; i++)); do
              if banner_up; then break; fi
              sleep 5
          done

          echo
          echo ">>> ACTION: enter your PIN and touch the Yubikey when prompted (install phase)."
          for ((i = 0; i < 5; i++)); do
              if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                  -o IdentitiesOnly=yes -i "$repo/files/public/ssh/yubikey.pub" \
                  -o PreferredAuthentications=publickey -o ConnectTimeout=120 \
                  -p "$ssh_port" root@127.0.0.1 true; then break; fi
              echo "[*] SSH master not established yet (touch the Yubikey), retrying ..."
              sleep 2
          done

          echo "[*] Running swarsel-bootstrap against the VM"
          FLAKE="$work" swarsel-bootstrap --non-interactive \
              -n "$target_config" -d 127.0.0.1 --port "$ssh_port" -a "$target_arch"

          echo "[*] Assertion 1: .sops.yaml registers toto's age key"
          grep -E "&$target_config age1" "$work/.sops.yaml"

          echo "[*] Assertion 2: the deployed host can decrypt its re-keyed secret"
          echo ">>> ACTION: touch the Yubikey to fetch the deployed host key (PIN is cached)."
          for ((i = 0; i < 5; i++)); do
              if scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                  -o IdentitiesOnly=yes -i "$repo/files/public/ssh/yubikey.pub" \
                  -o PreferredAuthentications=publickey -o ConnectTimeout=120 -P "$ssh_port" \
                  root@127.0.0.1:/etc/ssh/ssh_host_ed25519_key "$tmp/hostkey"; then break; fi
              echo "[*] retrying host-key fetch (touch the Yubikey) ..."
              sleep 2
          done
          SOPS_AGE_KEY=$(ssh-to-age -private-key -i "$tmp/hostkey")
          export SOPS_AGE_KEY
          got=$(sops decrypt --extract "[\"$secret_key\"]" \
              "$work/hosts/nixos/$target_arch/$target_config/secrets/secret.yaml")

          if [[ $got == "$secret_plaintext" ]]; then
              echo "[+] PASS: secret deployment verified ($secret_key decrypts on the deployed host)"
          else
              echo "[!] FAIL: expected '$secret_plaintext', got '$got'"
              exit 1
          fi
        '';
      };
    };
}
