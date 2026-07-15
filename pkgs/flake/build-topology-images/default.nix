{
  self,
  name,
  stdenv,
  git,
  nix,
  chromium,
  imagemagick,
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
      --override-input topologyPrivate "${self}/files/topology/private" \
      "$flake#topology.${stdenv.hostPlatform.system}.config.output")"

    svg="$result/main.svg"
    read -r width height < <(
      sed -n 's/.*<svg[^>]*width="\([0-9.]*\)"[^>]*height="\([0-9.]*\)".*/\1 \2/p' "$svg" | head -1
    )
    [[ -n "$width" && -n "$height" ]] \
      || { echo "could not parse svg dimensions from $svg" >&2; exit 1; }

    profile="$(mktemp -d)"
    trap 'rm -rf "$profile"' EXIT

    chromium \
      --headless \
      --no-sandbox \
      --hide-scrollbars \
      --force-device-scale-factor=1 \
      --user-data-dir="$profile" \
      --default-background-color=00000000 \
      --window-size="''${width%.*},''${height%.*}" \
      --screenshot="$out/topology.png" \
      "file://$svg"

    magick "$out/topology.png" -resize 500x "$out/topology_small.png"

    echo "wrote $out/topology.png and $out/topology_small.png"
  '';
}
