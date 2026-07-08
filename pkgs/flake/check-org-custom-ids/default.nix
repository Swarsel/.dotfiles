{
  name,
  emacs-nox,
  writers,
  writeShellApplication,
  ...
}:

let
  script = writers.writePython3Bin "check-org-custom-ids-py" { flakeIgnore = [ "E501" ]; } ''
    import argparse
    import os
    import re
    import subprocess
    import sys
    from pathlib import Path

    HEADING = re.compile(r"^\*+ ")
    PROPERTIES = re.compile(r"^[ \t]*:PROPERTIES:[ \t]*$", re.IGNORECASE)
    CUSTOM_ID = re.compile(r"^[ \t]*:CUSTOM_ID:[ \t]*\S", re.IGNORECASE)
    END = re.compile(r"^[ \t]*:END:[ \t]*$", re.IGNORECASE)

    FIX_ELISP = """
    (progn
      (require 'org)
      (require 'org-id)
      (find-file (car command-line-args-left))
      (org-mode)
      (org-map-entries
       (lambda ()
         (let ((id (org-entry-get (point) "CUSTOM_ID")))
           (unless (and id (stringp id) (string-match-p "\\\\S-" id))
             (org-entry-put (point) "CUSTOM_ID" (org-id-new "h"))))))
      (save-buffer))
    """


    def missing_ids(path: Path) -> list[tuple[int, str]]:
        lines = path.read_text(encoding="utf-8").splitlines()
        missing = []
        i = 0
        n = len(lines)
        while i < n:
            if not HEADING.match(lines[i]):
                i += 1
                continue
            heading_line, heading_text = i + 1, lines[i]
            i += 1
            if i >= n or not PROPERTIES.match(lines[i]):
                missing.append((heading_line, heading_text))
                continue
            i += 1
            found = False
            while i < n and not END.match(lines[i]):
                if CUSTOM_ID.match(lines[i]):
                    found = True
                i += 1
            if not found:
                missing.append((heading_line, heading_text))
        return missing


    def report(path: Path, missing: list[tuple[int, str]]) -> None:
        print(f"{path}: {len(missing)} heading(s) without a :CUSTOM_ID:")
        for line, text in missing:
            print(f"  {path}:{line}: {text}")


    def generate(path: Path, emacs: str) -> None:
        subprocess.run(
            [emacs, "--batch", "--eval", FIX_ELISP, str(path)],
            check=True,
        )


    def main() -> int:
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "--check",
            action="store_true",
            help="only report headings missing a :CUSTOM_ID:, do not generate them",
        )
        parser.add_argument(
            "--emacs",
            default=os.environ.get("EMACS", "emacs"),
            help="path to the emacs binary used to generate CUSTOM_IDs",
        )
        parser.add_argument("files", nargs="+", type=Path)
        args = parser.parse_args()

        status = 0
        for path in args.files:
            missing = missing_ids(path)
            if not missing:
                continue
            if args.check:
                status = 1
                report(path, missing)
            else:
                report(path, missing)
                generate(path, args.emacs)
                print(f"{path}: generated {len(missing)} CUSTOM_ID(s); review and re-stage.")
                status = 1
        return status


    if __name__ == "__main__":
        sys.exit(main())
  '';
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ emacs-nox ];
  text = ''
    export EMACS=${emacs-nox}/bin/emacs
    exec ${script}/bin/check-org-custom-ids-py "$@"
  '';
}
