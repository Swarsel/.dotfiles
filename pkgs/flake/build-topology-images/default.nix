{
  root,
  name,
  chromium,
  git,
  imagemagick,
  nix,
  stdenv,
  writeShellApplication,
  ...
}:

writeShellApplication {
  inherit name;
  runtimeInputs = [
    git
    nix
    chromium
    imagemagick
  ];
  text = ''
    flake="''${FLAKE:-$(git rev-parse --show-toplevel 2> /dev/null || pwd)}"
    [[ -e "$flake/flake.nix" ]] \
      || { echo "could not locate dotfiles flake (set \$FLAKE)" >&2; exit 1; }

    out="$flake/files/topology"
    mkdir -p "$out"

    result="$(nix build --no-link --print-out-paths --builders "" \
      --override-input topologyPrivate "${root "files/topology/private"}" \
      "$flake#topology.${stdenv.hostPlatform.system}.config.output")"

    svg="$result/main.svg"
    read -r width height < <(
      sed -n 's/.*<svg[^>]*width="\([0-9.]*\)"[^>]*height="\([0-9.]*\)".*/\1 \2/p' "$svg" | head -1
    )
    [[ -n "$width" && -n "$height" ]] \
      || { echo "could not parse svg dimensions from $svg" >&2; exit 1; }

    work="$(mktemp -d)"
    trap 'rm -rf "$work"' EXIT

    stripHeight=4096
    fullHeight=$(( ''${height%.*} + 1 ))
    strips=()
    for (( offset = 0; offset < fullHeight; offset += stripHeight )); do
      strip="$work/strip-$(printf '%05d' "$offset").png"
      printf '<!doctype html><body style="margin:0"><img src="file://%s" style="display:block;margin-top:-%dpx"></body>' \
        "$svg" "$offset" > "$work/strip.html"
      chromium \
        --headless \
        --no-sandbox \
        --hide-scrollbars \
        --allow-file-access-from-files \
        --force-device-scale-factor=1 \
        --user-data-dir="$work/profile" \
        --default-background-color=00000000 \
        --window-size="''${width%.*},$(( fullHeight - offset < stripHeight ? fullHeight - offset : stripHeight ))" \
        --screenshot="$strip" \
        "file://$work/strip.html"
      strips+=("$strip")
    done

    magick "''${strips[@]}" +repage -append +repage "$out/topology.png"
    magick "$out/topology.png" -resize 500x "$out/topology_small.png"

    echo "wrote $out/topology.png and $out/topology_small.png"
  '';
}
