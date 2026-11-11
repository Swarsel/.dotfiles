{ self, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      secretKey = "toto-deploy-test";
    in
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.bootstrap-install-test = pkgs.writeShellApplication {
        name = "bootstrap-install-test";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          pkgs.gnupg
          pkgs.openssh
          pkgs.qemu
          pkgs.rsync
          pkgs.sops
          pkgs.ssh-to-age
          self.packages.${system}.swarsel-bootstrap
        ];
        text = ''
          target_config=toto
          secret_key="${secretKey}"
          secret_plaintext="bootstrap-secret-deployment-ok"
          ssh_port=2222

          repo=$(git rev-parse --show-toplevel)
          tmp=$(mktemp -d /tmp/bootstrap-test.XXXXXX)
          work="$tmp/dotfiles"
          host_dir="$work/hosts/nixos/${system}/$target_config"
          qemu_pid=""

          cleanup() {
              rm -rf "$tmp"
              if [[ -n $qemu_pid ]]; then
                  kill "$qemu_pid"
              fi
          }
          trap cleanup EXIT

          SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
          export SSH_AUTH_SOCK

          ssh_up() {
              timeout 3 bash -c "exec 3<> /dev/tcp/127.0.0.1/$ssh_port; head -c 4 <&3" 2> /dev/null | grep -q SSH
          }

          wait_for_ssh() {
              for _ in $(seq 120); do
                  if ssh_up; then
                      return 0
                  fi
                  sleep 5
              done
              echo "no ssh on port $ssh_port after 10 minutes" >&2
              exit 1
          }

          mkdir -p "$host_dir"
          rsync -a --filter=':- .gitignore' --exclude=.git "$repo"/ "$work"/
          install -m644 ${pkgs.writeText "toto.nix" ''
            {
              inputs,
              lib,
              pkgs,
              minimal,
              ...
            }:
            {
              imports = [
                inputs.self.modules.nixos.disk-single-root
                ./hardware-configuration.nix
              ]
              ++ lib.optionals (!minimal) [
                inputs.self.modules.nixos.profile-minimal
              ];

              swarselsystems = {
                info = "~SwarselSystems~ bootstrap test host";
                isBtrfs = true;
                isCrypted = false;
                isImpermanence = true;
                isLaptop = false;
                isLinux = true;
                isSecureBoot = false;
                isSwap = true;
                rootDisk = "/dev/vda";
                swapSize = "2G";
              };

              sops.secrets.${secretKey} = { };
              environment.systemPackages = [ pkgs.yubikey-manager ];

              networking.firewall.enable = false;
              nixpkgs.hostPlatform = "${system}";

              node.lockFromBootstrapping = lib.mkForce false;
            }
          ''} "$host_dir/default.nix"
          echo "{ }" > "$host_dir/hardware-configuration.nix"
          sed -i "/^host_configs = {$/a\\  $target_config = {\n    type   = \"nixos\"\n    arch   = \"${system}\"\n    guests = []\n  }" "$work/tofu/sops/terraform.tfvars"
          echo "touch the yubikey to add the test secret"
          sops set "$work/secrets/root.yaml" "[\"hosts\"][\"$target_config\"][\"$secret_key\"]" "\"$secret_plaintext\""
          git -C "$work" init -q -b main
          git -C "$work" add -A
          git -C "$work" -c user.email=test@example.org -c user.name=test -c commit.gpgsign=false commit -q --no-verify -m "bootstrap-test base"

          cp ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd "$tmp/OVMF_VARS.fd"
          chmod u+w "$tmp/OVMF_VARS.fd"
          qemu-img create -q -f qcow2 "$tmp/disk.qcow2" 32G
          qemu-system-x86_64 \
              -enable-kvm -m 8192 -smp 4 \
              -drive if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd \
              -drive if=pflash,format=raw,file="$tmp/OVMF_VARS.fd" \
              -drive id=hd0,file="$tmp/disk.qcow2",if=none,format=qcow2 \
              -device virtio-blk-pci,drive=hd0,bootindex=1 \
              -drive id=cd0,file="$(echo ${self.packages.${system}.live-iso}/iso/*.iso)",if=none,media=cdrom \
              -device ide-cd,drive=cd0,bootindex=2 \
              -boot menu=off \
              -netdev "user,id=net0,hostfwd=tcp::$ssh_port-:22" -device virtio-net,netdev=net0 \
              -display none -serial "file:$tmp/console.log" &
          qemu_pid=$!
          wait_for_ssh

          echo "running swarsel-bootstrap, touch the yubikey for the ssh login and the rekey"
          FLAKE="$work" swarsel-bootstrap -p "$ssh_port" "$target_config" 127.0.0.1

          if ! grep -q "&$target_config age1" "$work/.sops.yaml"; then
              echo ".sops.yaml has no age key for $target_config" >&2
              exit 1
          fi

          for _ in $(seq 60); do
              ssh_up || break
              sleep 2
          done
          wait_for_ssh

          fetch_hostkey() {
              scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                  -o IdentitiesOnly=yes -i "$repo/files/public/ssh/yubikey.pub" \
                  -o PreferredAuthentications=publickey -P "$ssh_port" \
                  root@127.0.0.1:/etc/ssh/ssh_host_ed25519_key "$tmp/hostkey"
          }

          echo "touch the yubikey to fetch the host key of the installed system"
          fetch_hostkey || fetch_hostkey || fetch_hostkey
          SOPS_AGE_KEY=$(ssh-to-age -private-key -i "$tmp/hostkey")
          export SOPS_AGE_KEY
          got=$(sops decrypt --extract "[\"secrets__root.yaml\"][\"hosts\"][\"$target_config\"][\"$secret_key\"]" \
              "$work/secrets/rekeyed/$target_config.yaml")

          if [[ $got != "$secret_plaintext" ]]; then
              echo "expected '$secret_plaintext', got '$got'" >&2
              exit 1
          fi
        '';
      };
    };
}
