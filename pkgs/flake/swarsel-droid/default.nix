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
    builder=belchsfactory
    path=$(ssh "$builder" readlink -f "/nix/var/nix/profiles/$DROID_PROFILE")
    nix copy --no-check-sigs --from "ssh://$builder" "$path"

    # proot cannot allocate a pty, so builds that fail on the phone are done on the builder instead
    for _ in 1 2 3; do
        if log=$("$path/activate" 2>&1 | tee /dev/stderr); then
            exit 0
        fi
        drv=$(grep -oE '/nix/store/[a-z0-9]{32}-[a-zA-Z0-9+._?=-]+\.drv' <<<"$log" | head -n 1) || exit 1
        nix copy --no-check-sigs --to "ssh://$builder" "$drv"
        mapfile -t outputs < <(ssh "$builder" nix-store --realise "$drv")
        nix copy --no-check-sigs --from "ssh://$builder" "''${outputs[@]}"
    done
    exit 1
  '';
}
