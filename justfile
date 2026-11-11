sops_files := "git grep -lz --untracked 'ENC\\[AES256_GCM' -- ':!secrets/rekeyed'"

default:
  @just --list

check:
  nix flake check --keep-going

follows-check *ARGS:
  follow-nix {{ARGS}}

iso CONFIG="live-iso":
  rm -rf result
  nix build --print-out-paths .#{{CONFIG}}

bootstrap-test:
  nix develop .#deploy --command nix run .#bootstrap-install-test

sandbox:
  sudo install -d -m 0700 -o "$USER" /run/sandbox-tls
  sudo install -m 0400 -o "$USER" /run/secrets/sandbox-wildcard-key /run/sandbox-tls/wildcard.key
  sudo systemd-run --collect --pty --same-dir --wait --uid="$USER" \
    -p AmbientCapabilities=CAP_NET_BIND_SERVICE \
    "$(nix build --no-link --print-out-paths .#nixosConfigurations.vacanthouse.config.system.build.vm)/bin/run-vacanthouse-vm"

sandbox-test:
  nix build -L --no-link .#sandbox-test

sync:
  nix run .#swarsel-sync-org

topology:
  nix run .#swarsel-topology

iso-install DRIVE: iso
  sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

bootstrap DEST CONFIG *ARGS:
  nix develop .#deploy --command zsh -c "SSH_AUTH_SOCK=\$(gpgconf --list-dirs agent-ssh-socket) swarsel-bootstrap {{ARGS}} {{CONFIG}} {{DEST}}"

rekey *ARGS:
  {{sops_files}} | xargs -0 -n1 sops updatekeys --yes
  nix run --builders '' .#sops-rekey -- --add-to-git rekey {{ARGS}}
  nix run --inputs-from . piix#pii -- lock

secret-set PATH:
  #!/usr/bin/env bash
  set -euo pipefail
  value=$(cat)
  sops set secrets/root.yaml '{{ '["' + replace(PATH, "/", '"]["') + '"]' }}' "$(printf '%s' "$value" | jq -Rs .)"
  git add secrets/root.yaml

secret-get PATH:
  sops decrypt --extract '{{ '["' + replace(PATH, "/", '"]["') + '"]' }}' secrets/root.yaml

secret-edit FILE="":
  #!/usr/bin/env bash
  set -euo pipefail
  file="{{FILE}}"
  if [ -z "$file" ]; then
    file=$({{sops_files}} | tr '\0' '\n' | fzf)
  fi
  sops "$file"
  if [[ $file == *.nix.enc ]]; then
    nix run --inputs-from . piix#pii -- lock
  fi

free-id:
  nix eval .#nodes --apply ' \
    nodes: \
    let \
      ids = node: \
        map (user: user.uid) (builtins.attrValues node.config.users.users) \
        ++ map (group: group.gid) (builtins.attrValues node.config.users.groups) \
        ++ builtins.concatMap (persistent: [ persistent.uid persistent.gid ]) (builtins.attrValues node.config.users.persistentIds); \
      used = builtins.concatMap ids (builtins.filter (node: node.class == "nixos") (builtins.attrValues nodes)); \
      free = id: if builtins.elem id used then free (id - 1) else id; \
    in \
    free 999'

droid HOST="magicant":
  #!/usr/bin/env bash
  set -euo pipefail
  path=$(nix build --impure --no-link --print-out-paths \
    --option extra-substituters https://nix-on-droid.cachix.org \
    --option extra-trusted-public-keys nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU= \
    .#nixOnDroidConfigurations.{{HOST}}.activationPackage)
  nix copy --to ssh://belchsfactory "$path"
  ssh belchsfactory nix-env --profile /nix/var/nix/profiles/droid-{{HOST}} --set "$path"

pii *ARGS:
  nix run --inputs-from . piix#pii -- {{ARGS}}
