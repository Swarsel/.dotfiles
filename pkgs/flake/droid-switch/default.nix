{
  name,
  coreutils,
  gnugrep,
  openssh,
  writeShellApplication,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    coreutils
    gnugrep
    openssh
  ];
  text = ''
    builder=''${DROID_BUILDER:-belchsfactory}
    if [[ $# -ge 1 ]]; then
        path=$1
    elif [[ -n ''${DROID_PROFILE:-} ]]; then
        path=$(ssh "$builder" readlink -f "/nix/var/nix/profiles/$DROID_PROFILE")
        echo "latest staged generation: $path" >&2
    else
        echo "usage: ${name} [activation package]  (or set DROID_PROFILE)" >&2
        exit 1
    fi
    nix copy --no-check-sigs --from "ssh://$builder" "$path"
    for _ in 1 2 3; do
        if log=$("$path/activate" 2>&1 | tee /dev/stderr); then
            exit 0
        fi
        drv=$(grep -oE '/nix/store/[a-z0-9]{32}-[a-zA-Z0-9+._?=-]+\.drv' <<< "$log" | head -n 1 || true)
        if [[ -z $drv ]]; then
            exit 1
        fi
        echo "building $drv on $builder" >&2
        nix copy --no-check-sigs --to "ssh://$builder" "$drv"
        mapfile -t outputs < <(ssh "$builder" nix-store --realise "$drv")
        nix copy --no-check-sigs --from "ssh://$builder" "''${outputs[@]}"
    done
    exit 1
  '';
}
