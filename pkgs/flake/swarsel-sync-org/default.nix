{
  name,
  writers,
  ...
}:

writers.writePython3Bin name { } ''
  import difflib
  import re
  import sys
  from collections import Counter
  from pathlib import Path

  org = Path("SwarselSystems.org")
  header = re.compile(r"^\s*#\+begin_src\s.*?:tangle\s+(\S+)", re.I)

  with org.open() as f:
      old = f.readlines()

  targets = Counter(m[1] for line in old if (m := header.match(line)))

  new = []
  source = None
  for line in old:
      if source:
          if line.strip().lower() != "#+end_src":
              continue
          content = source.read_text().removesuffix("\n").split("\n")
          new += [f"  {c}\n" if c.strip() else "\n" for c in content]
          source = None

      new.append(line)

      m = header.match(line)
      if not m or targets[m[1]] > 1 or ":noweb yes" in line:
          continue
      if Path(m[1]).exists():
          source = Path(m[1])

  if new == old:
      sys.exit()

  if "--dry-run" in sys.argv:
      sys.stdout.writelines(
          difflib.unified_diff(old, new, f"a/{org}", f"b/{org}")
      )
      sys.exit(1)

  org.write_text("".join(new))
''
