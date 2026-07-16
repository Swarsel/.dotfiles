{
  name,
  writers,
  ...
}:

writers.writePython3Bin name
  {
    flakeIgnore = [
      "E501"
      "F541"
    ];
  }
  ''
    import argparse
    import re
    import sys
    from collections import Counter
    from pathlib import Path
    from typing import Optional


    def parse_tangle_path(line: str) -> Optional[str]:
        m = re.search(r":tangle\s+(\S+)", line)
        if not m:
            return None
        path = m.group(1)
        if path == "no":
            return None
        return path


    def parse_shebang(line: str) -> Optional[str]:
        m = re.search(r":shebang\s+(.*?)(?=\s+:[A-Za-z0-9_-]+\s|\s*$)", line)
        if not m:
            return None
        value = m.group(1).strip()
        if value == "":
            return None
        return value


    def has_noweb(line: str) -> bool:
        return bool(re.search(r":noweb\s+yes", line))


    def indent_content(content: str, spaces: int = 2) -> str:
        prefix = " " * spaces
        lines = content.split("\n")
        result = []
        for line in lines:
            if line.strip():
                result.append(prefix + line)
            else:
                result.append("")
        return "\n".join(result)


    def main():
        parser = argparse.ArgumentParser(description="Sync tangled files back into org source blocks")
        parser.add_argument("--dry-run", "-n", action="store_true", help="Show what would change without modifying the file")
        parser.add_argument("--org-file", default="SwarselSystems.org", help="Path to the org file (default: SwarselSystems.org)")
        parser.add_argument("--repo-root", default=None, help="Repository root (default: parent of org file)")
        parser.add_argument("--show-updated", action="store_true", help="List every updated block with its org line")
        parser.add_argument("--show-unchanged", action="store_true", help="List every unchanged block with its org line")
        parser.add_argument("--show-skipped", action="store_true", help="List every skipped block with its org line and the skip reason (noweb, multi-block, missing)")
        args = parser.parse_args()

        org_path = Path(args.org_file).resolve()
        if not org_path.exists():
            print(f"Error: {org_path} not found", file=sys.stderr)
            sys.exit(1)

        repo_root = Path(args.repo_root).resolve() if args.repo_root else org_path.parent

        with open(org_path, "r") as f:
            lines = f.readlines()

        tangle_counts: Counter[str] = Counter()
        for line in lines:
            lower = line.lower().strip()
            if lower.startswith("#+begin_src"):
                tp = parse_tangle_path(line)
                if tp:
                    tangle_counts[tp] += 1

        multi_target_files = {p for p, count in tangle_counts.items() if count > 1}

        output_lines: list[str] = []
        i = 0
        updated_blocks: list[tuple[str, int]] = []
        unchanged_blocks: list[tuple[str, int]] = []
        skipped_blocks: list[tuple[str, int, str]] = []

        while i < len(lines):
            line = lines[i]
            lower = line.strip().lower()

            if not lower.startswith("#+begin_src"):
                output_lines.append(line)
                i += 1
                continue

            tangle_path = parse_tangle_path(line)

            if tangle_path is None:
                output_lines.append(line)
                i += 1
                continue

            if has_noweb(line):
                skipped_blocks.append((tangle_path, i + 1, "noweb"))
                while i < len(lines):
                    output_lines.append(lines[i])
                    if lines[i].strip().lower() == "#+end_src":
                        i += 1
                        break
                    i += 1
                continue

            if tangle_path in multi_target_files:
                skipped_blocks.append((tangle_path, i + 1, "multi-block"))
                while i < len(lines):
                    output_lines.append(lines[i])
                    if lines[i].strip().lower() == "#+end_src":
                        i += 1
                        break
                    i += 1
                continue

            file_path = repo_root / tangle_path
            if not file_path.exists():
                skipped_blocks.append((tangle_path, i + 1, "missing"))
                while i < len(lines):
                    output_lines.append(lines[i])
                    if lines[i].strip().lower() == "#+end_src":
                        i += 1
                        break
                    i += 1
                continue

            file_content = file_path.read_text()

            shebang = parse_shebang(line)
            if shebang:
                file_lines = file_content.splitlines()
                if file_lines and file_lines[0].strip() == shebang:
                    file_content = "\n".join(file_lines[1:])

            if file_content.endswith("\n"):
                file_content = file_content[:-1]

            new_body = indent_content(file_content)

            old_body_lines: list[str] = []
            j = i + 1
            while j < len(lines) and lines[j].strip().lower() != "#+end_src":
                old_body_lines.append(lines[j])
                j += 1

            old_body = "".join(old_body_lines)
            if old_body.endswith("\n"):
                old_body = old_body[:-1]

            if old_body == new_body:
                unchanged_blocks.append((tangle_path, i + 1))
                while i < len(lines):
                    output_lines.append(lines[i])
                    if lines[i].strip().lower() == "#+end_src":
                        i += 1
                        break
                    i += 1
                continue

            updated_blocks.append((tangle_path, i + 1))
            output_lines.append(line)
            output_lines.append(new_body + "\n")
            i += 1
            while i < len(lines) and lines[i].strip().lower() != "#+end_src":
                i += 1
            if i < len(lines):
                output_lines.append(lines[i])
                i += 1

        updated = len(updated_blocks)
        unchanged = len(unchanged_blocks)
        skip_counts = Counter(reason for _, _, reason in skipped_blocks)
        total = updated + unchanged + len(skipped_blocks)
        print(f"\nSync summary:")
        print(f"  Total tangled blocks: {total}")
        print(f"  Updated:              {updated}")
        print(f"  Unchanged:            {unchanged}")
        print(f"  Skipped (noweb):      {skip_counts['noweb']}")
        print(f"  Skipped (multi-block):{skip_counts['multi-block']}")
        print(f"  Skipped (missing):    {skip_counts['missing']}")

        if args.show_updated and updated_blocks:
            print(f"\nUpdated blocks:")
            for path, line_no in updated_blocks:
                print(f"  {path} (line {line_no})")

        if args.show_unchanged and unchanged_blocks:
            print(f"\nUnchanged blocks:")
            for path, line_no in unchanged_blocks:
                print(f"  {path} (line {line_no})")

        if args.show_skipped and skipped_blocks:
            print(f"\nSkipped blocks:")
            for path, line_no, reason in skipped_blocks:
                print(f"  {path} (line {line_no}, {reason})")

        if not args.dry_run and updated > 0:
            with open(org_path, "w") as f:
                f.writelines(output_lines)
            print(f"\nWrote {org_path}")
        elif args.dry_run:
            print(f"\nDry run — no changes written.")


    if __name__ == "__main__":
        main()
  ''
