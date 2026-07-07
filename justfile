default:
  @just --list

check:
  nix flake check --keep-going

check-trace:
  nix flake check --show-trace

update:
  nix flake update

follows-check *ARGS:
  follow-nix {{ARGS}}

iso CONFIG="live-iso":
  rm -rf result
  nix build --print-out-paths .#live-iso

demo-test TEST="demo-install-test":
  nix build -L --no-link --print-out-paths .#{{TEST}} --override-input repoSecrets path:./files/demo --override-input vbc-nix path:./files/stub --no-write-lock-file

demo-full-test: (demo-test "demo-full-test")

bootstrap-test:
  nix develop .#deploy --command nix run .#bootstrap-install-test

iso-install DRIVE: iso
  sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

dd DRIVE ISO:
  sudo dd if=$(eza --sort changed {{ISO}} | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

sync USER HOST:
  rsync -rltv --filter=':- .gitignore' -e "ssh -l {{USER}}" . {{USER}}@{{HOST}}:.dotfiles/

sync-secrets USER HOST:
  rsync -rltv -e "ssh -l {{USER}}" /var/tmp/nix-import-encrypted/$(id -u)/ {{USER}}@{{HOST}}:/var/tmp/nix-import-encrypted/0

bootstrap DEST CONFIG ARCH="x86_64-linux" NODISKODEPS="":
  nix develop .#deploy --command zsh -c "swarsel-bootstrap {{NODISKODEPS}} -n {{CONFIG}} -d {{DEST}} -a {{ARCH}}"

updatekeys:
  find . -path ./files/public -prune -o -path './.github' -prune -o \( -name '*.yaml' -o -name '*.json' -o -name '*.nix.enc' \) -not -name '.sops.yaml' -not -name 'swarsel.yaml' -not -name '.pre-commit-config.yaml' -print0 | xargs --null -I{} sops updatekeys --yes {}

decrypt:
  #!/usr/bin/env bash
  set -euo pipefail
  src=$(nix flake metadata --json | python3 -c 'import json, sys; print(json.load(sys.stdin)["path"])')
  find "$src" -name '*.nix.enc' -print0 | xargs --null -I{} ./files/scripts/sops-decrypt-and-cache.sh --print-out-path {}

decrypt-clean:
  rm -rf "/var/tmp/nix-import-encrypted/$(id -u)"

secret-edit FILE="":
  #!/usr/bin/env bash
  set -euo pipefail
  file="{{FILE}}"
  if [ -z "$file" ]; then
    file=$(find . -path ./files/public -prune -o -path './.github' -prune -o \( -name '*.yaml' -o -name '*.json' -o -name '*.nix.enc' \) -not -name '.sops.yaml' -not -name 'swarsel.yaml' -not -name '.pre-commit-config.yaml' -print0 | xargs -0 grep -lE 'ENC\[AES256_GCM' | sort | fzf)
  fi
  sops "$file"

free-ids COUNT="5":
  #!/usr/bin/env python3
  import collections, itertools, pathlib, re
  mkids = re.compile(r"([\w$.{}-]+)\s*=\s*(?:lib\.mkIf[^(]*\()?confLib\.mkIds (\d+)")
  rawid = re.compile(r"\b(uid|gid) = (\d+);")
  used = collections.defaultdict(set)
  for root in ("modules", "hosts"):
      for f in pathlib.Path(root).rglob("*.nix"):
          for i, line in enumerate(f.read_text().splitlines(), 1):
              for m in mkids.finditer(line):
                  name = m.group(1).split(".")[-1]
                  if "${" in name:
                      name = f.stem
                  used[int(m.group(2))].add((name, f"{f}:{i}"))
              if not mkids.search(line):
                  for m in rawid.finditer(line):
                      used[int(m.group(2))].add((None, f"{f}:{i}"))
  clusters = [[]]
  for i in sorted(used):
      if clusters[-1] and i - clusters[-1][-1] > 50:
          clusters.append([])
      clusters[-1].append(i)
  main = max(clusters, key=len)
  block = {i: used[i] for i in main}
  outliers = {i: used[i] for i in sorted(used) if i not in block}
  lo, hi = min(block), max(block)
  def ranges(nums):
      out = []
      for _, grp in itertools.groupby(enumerate(sorted(nums)), lambda t: t[1] - t[0]):
          grp = [g[1] for g in grp]
          out.append(str(grp[0]) if len(grp) == 1 else f"{grp[0]}-{grp[-1]}")
      return " ".join(out) if out else "none"
  print(f"id block: {ranges(block)}")
  conflicts = {i: names for i, names in block.items() if len({n for n, _ in names if n}) > 1}
  if conflicts:
      print("\nCONFLICTS (same id, different names):")
      for i, names in sorted(conflicts.items()):
          print(f"  {i}:")
          for name, loc in sorted(names, key=str):
              print(f"    {name} ({loc})")
  gaps = [i for i in range(lo, hi + 1) if i not in block]
  print(f"free inside block: {ranges(gaps) if gaps else 'none'}")
  print(f"next free below {lo}: {' '.join(str(i) for i in range(lo - 1, lo - 1 - {{COUNT}}, -1))}")
  print(f"next free above {hi}: {' '.join(str(i) for i in range(hi + 1, hi + 1 + {{COUNT}}))}")
  if outliers:
      print(f"\noutside block (dedicated service ids): {ranges(outliers)}")

fmt:
  nix fmt

build HOST:
  nix build --no-link --print-out-paths .#nixosConfigurations.{{HOST}}.config.system.build.toplevel

home HOST USER="swarsel":
  nix build --no-link --print-out-paths .#nixosConfigurations.{{HOST}}.config.home-manager.users.{{USER}}.home.activationPackage

pii MODE="quick":
  #!/usr/bin/env python3
  import json, os, pathlib, subprocess, sys
  def run(expr_or_attr, flake):
      cmd = ["nix", "eval", "--json"] + (
          [f".#{expr_or_attr[0]}", "--apply", expr_or_attr[1]] if flake else ["--impure", "--expr", expr_or_attr]
      )
      r = subprocess.run(cmd, capture_output=True, text=True)
      if r.returncode != 0:
          sys.stderr.write(r.stderr)
          return None
      return json.loads(r.stdout)
  SAN = (
      'let sanitize = v: if builtins.isFunction v then "<function>"'
      " else if builtins.isAttrs v then builtins.mapAttrs (_: sanitize) v"
      " else if builtins.isList v then map sanitize v else v; in sanitize"
  )
  if "{{MODE}}" == "full":
      out = {"globals": run(("globals.x86_64-linux", SAN), True), "common": None, "hosts": {}}
      for kind in ("nixosConfigurations", "darwinConfigurations"):
          for host in run((kind, "builtins.attrNames"), True) or []:
              sec = run((f"{kind}.{host}.config.repo.secrets", SAN), True)
              if sec is None:
                  out["hosts"][host] = "<eval failed>"
                  continue
              common = sec.pop("common", None)
              if out["common"] is None:
                  out["common"] = common
              out["hosts"][host] = sec
      print(json.dumps(out, indent=2))
      sys.exit(0)
  d = pathlib.Path(f"/var/tmp/nix-import-encrypted/{os.getuid()}")
  if not d.is_dir():
      sys.exit(f"{d} does not exist, run `just decrypt` first")
  best = {}
  for f in d.iterdir():
      if not f.name.endswith(".nix") or "-" not in f.name:
          continue
      rel = f.name.split("-", 1)[1].removeprefix("source%")
      mtime = f.stat().st_mtime
      if rel not in best or mtime > best[rel][0]:
          best[rel] = (mtime, f)
  entries = [
      ".".join(json.dumps(seg) for seg in rel.removesuffix(".nix").split("%")) + f' = load "{f}";'
      for rel, (_, f) in sorted(best.items())
  ]
  prelude = (
      'let sanitize = v: let t = builtins.tryEval v; in'
      ' if !t.success then "<eval error>"'
      ' else if builtins.isFunction t.value then "<function>"'
      " else if builtins.isAttrs t.value then builtins.mapAttrs (_: sanitize) t.value"
      " else if builtins.isList t.value then map sanitize t.value"
      " else t.value;"
      " load = p: let v = import p; in sanitize ("
      ' if builtins.isFunction v then v (builtins.mapAttrs (_: _: throw "arg") (builtins.functionArgs v)) else v); in '
  )
  result = run(prelude + "{ " + " ".join(entries) + " }", False)
  if result is None:
      sys.exit(1)
  print(json.dumps(result, indent=2))
