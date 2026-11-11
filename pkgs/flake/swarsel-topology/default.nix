{
  root,
  name,
  chromium,
  git,
  imagemagick,
  libxml2,
  nix,
  stdenv,
  writeShellApplication,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    chromium
    git
    imagemagick
    libxml2
    nix
  ];
  text = ''
    flake=''${FLAKE:-$(git rev-parse --show-toplevel)}
    out=$flake/files/topology
    svg=$(nix build --no-link --print-out-paths --builders "" \
      --override-input topologyPrivate "${root "files/topology/private"}" \
      "$flake#topology.${stdenv.hostPlatform.system}.config.output")/main.svg

    width=$(xmllint --xpath 'string(/*/@width)' "$svg")
    width=''${width%.*}
    height=$(xmllint --xpath 'string(/*/@height)' "$svg")
    height=$((''${height%.*} + 1))

    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT

    strips=()
    for ((offset = 0; offset < height; offset += 4096)); do
        printf '<!doctype html><body style="margin:0"><img src="file://%s" style="display:block;margin-top:-%dpx"></body>' "$svg" "$offset" > "$work/strip.html"
        strips+=("$work/strip-$offset.png")
        chromium --headless --no-sandbox --hide-scrollbars --allow-file-access-from-files \
            --force-device-scale-factor=1 --default-background-color=00000000 \
            --user-data-dir="$work/profile" \
            --window-size="$width,$((height - offset < 4096 ? height - offset : 4096))" \
            --screenshot="''${strips[-1]}" "file://$work/strip.html"
    done

    magick "''${strips[@]}" +repage -append +repage "$out/topology.png"
    magick "$out/topology.png" -resize 500x "$out/topology_small.png"
  '';
}
