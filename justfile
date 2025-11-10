default:
  @just --list

check:
  nix flake check --keep-going

check-trace:
  nix flake check --show-trace

update:
  nix flake update

iso CONFIG="live-iso":
  rm -rf result
  nix build --print-out-paths .#live-iso

iso-install DRIVE: iso
  sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

dd DRIVE ISO:
  sudo dd if=$(eza --sort changed {{ISO}} | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

sync USER HOST:
  rsync -rltv --filter=':- .gitignore' -e "ssh -l {{USER}}" . {{USER}}@{{HOST}}:.dotfiles/

bootstrap DEST CONFIG ARCH="x86_64-linux":
  nix develop .#deploy --command zsh -c "swarsel-bootstrap -n {{CONFIG}} -d {{DEST}} -a {{ARCH}}"
