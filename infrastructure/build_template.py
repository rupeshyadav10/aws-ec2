#!/usr/bin/env python3
"""Generate infrastructure/template.yaml from template.base.yaml + scripts/bootstrap-userdata.sh.

Why: the bootstrap script is the single source of truth. CloudFormation needs it inline
(Fn::Base64 + Fn::Sub), so this tiny builder injects it and swaps __BUCKET__ for the
real bucket reference. Run from anywhere:   python3 infrastructure/build_template.py
Author: Rupesh Kumar Yadav
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / "infrastructure" / "template.base.yaml"
SCRIPT = ROOT / "scripts" / "bootstrap-userdata.sh"
OUT = ROOT / "infrastructure" / "template.yaml"
INDENT = " " * 12  # must match the indentation under "Fn::Base64: !Sub |"


def main():
    script = SCRIPT.read_text()
    if "${" in script:
        raise SystemExit("bootstrap-userdata.sh must not contain ${...} (breaks Fn::Sub). Use $VAR instead.")
    script = script.replace("__BUCKET__", "${BackupBucket}")
    body = "\n".join((INDENT + line) if line.strip() else "" for line in script.rstrip("\n").split("\n"))
    template = BASE.read_text().replace("__USERDATA__", body)
    OUT.write_text(template)
    print(f"Wrote {OUT.relative_to(ROOT)} ({len(template.splitlines())} lines)")


if __name__ == "__main__":
    main()
