default:
  @just --list

check:
  nix flake check --keep-going

check-trace:
  nix flake check --show-trace

update:
  nix flake update

iso:
  rm -rf result
  nix build .#nixosConfigurations.iso.config.system.build.isoImage && ln -sf result/iso/*.iso latest.iso

iso-install DRIVE: iso
  sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

sync USER HOST:
  rsync -av --filter=':- .gitignore' -e "ssh -l {{USER}}" . {{USER}}@{{HOST}}:.dotfiles/