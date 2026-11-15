#!/usr/bin/env python3
"""Repository documentation checks. Standard library only; run from anywhere.

  python scripts/check_docs.py

Checks:
  1. Relative Markdown links and image references resolve to real files.
  2. README.md contains the required sections.
  3. Every .json file parses.
  4. No likely secrets in repository files (private IPv4 addresses are warnings).
  5. Screenshot inventory in docs/screenshot-checklist.md matches the files on disk.

Exit code 1 if any check fails. Missing screenshots marked Pending are reported, not failed.
"""
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {".git", "__pycache__", ".claude", "_unredacted"}
TEXT_SUFFIXES = {".md", ".json", ".ndjson", ".yml", ".yaml", ".py", ".ps1", ".sh", ".kql",
                 ".eql", ".csv", ".txt", ".toml", ".conf", ".xml", ""}
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".webp"}

README_SECTIONS = [
    "Project overview", "Architecture", "Technology stack", "Lab setup", "KQL exercises",
    "EQL exercises", "Alert tuning", "MITRE ATT&CK mapping", "Investigation case studies",
    "Key findings", "Future development",
]

LINK_RE = re.compile(r"(!?)\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
FENCE_RE = re.compile(r"^(```|~~~).*?^\1[^\n]*$", re.S | re.M)
INLINE_CODE_RE = re.compile(r"`[^`\n]*`")

SECRET_PATTERNS = [
    ("private key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("AWS access key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("GitHub token", re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}\b|\bgithub_pat_[A-Za-z0-9_]{40,}\b")),
    ("Slack token", re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}\b")),
    ("bearer or API key header", re.compile(r"(?i)\bauthorization\s*:\s*(?:bearer|apikey|basic)\s+[A-Za-z0-9+/=._-]{16,}")),
    ("assigned credential", re.compile(
        r"(?i)\b(?:password|passwd|pwd|secret|api[_-]?key|access[_-]?key|token|enrollment[_-]?token)"
        r"\b[\"']?\s*[:=]\s*[\"']?(?![<$%{\[(])[A-Za-z0-9+/=_.!@#^&*-]{8,}")),
]
PRIVATE_IP_RE = re.compile(
    r"(?<![\d.])(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}"
    r"|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(?![\d./])")


def repo_files():
    for path in sorted(ROOT.rglob("*")):
        if path.is_file() and not (set(path.relative_to(ROOT).parts) & SKIP_DIRS):
            yield path


def rel(path):
    return path.relative_to(ROOT).as_posix()


def check_links(errors):
    count = 0
    for md in (p for p in repo_files() if p.suffix.lower() == ".md"):
        text = INLINE_CODE_RE.sub("", FENCE_RE.sub("", md.read_text(encoding="utf-8")))
        for bang, target in LINK_RE.findall(text):
            if re.match(r"^(?:[a-z][a-z0-9+.-]*:|#|//)", target, re.I):
                continue
            count += 1
            dest = (md.parent / unquote(target.split("#", 1)[0])).resolve()
            if not dest.exists():
                kind = "image" if bang else "link"
                errors.append(f"broken {kind} in {rel(md)}: {target}")
    return count


def check_readme(errors):
    readme = ROOT / "README.md"
    if not readme.exists():
        errors.append("README.md is missing")
        return
    headings = [h.lower() for h in re.findall(r"^#{1,6}\s+(.*)$", readme.read_text(encoding="utf-8"), re.M)]
    for section in README_SECTIONS:
        if not any(section.lower() in h for h in headings):
            errors.append(f"README.md is missing a required section: {section}")


def check_json(errors):
    count = 0
    for path in (p for p in repo_files() if p.suffix.lower() == ".json"):
        count += 1
        try:
            json.loads(path.read_text(encoding="utf-8-sig"))
        except ValueError as exc:
            errors.append(f"invalid JSON in {rel(path)}: {exc}")
    return count


def check_secrets(errors, warnings):
    me = Path(__file__).resolve()
    for path in repo_files():
        if path.suffix.lower() not in TEXT_SUFFIXES or path.resolve() == me:
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            continue
        for n, line in enumerate(lines, start=1):
            for name, pattern in SECRET_PATTERNS:
                if pattern.search(line):
                    errors.append(f"possible {name} in {rel(path)}:{n}")
            for ip in PRIVATE_IP_RE.findall(line):
                warnings.append(f"private IP address {ip} in {rel(path)}:{n}")


def check_screenshots(errors, warnings):
    checklist = ROOT / "docs" / "screenshot-checklist.md"
    shots_dir = ROOT / "screenshots"
    if not checklist.exists():
        errors.append("docs/screenshot-checklist.md is missing")
        return [], []
    on_disk = {p.name: p for p in shots_dir.rglob("*")
               if p.is_file() and p.suffix.lower() in IMAGE_SUFFIXES and "_unredacted" not in p.parts}
    captured, pending, listed = [], [], set()
    for line in checklist.read_text(encoding="utf-8").splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 7 or not re.fullmatch(r"`[^`]+\.(?:png|jpe?g|gif|webp)`", cells[1], re.I):
            continue
        name, folder, status = cells[1].strip("`"), cells[2], cells[6].lower()
        listed.add(name)
        expected = shots_dir / folder / name
        if expected.exists():
            captured.append(name)
            if status != "captured":
                errors.append(f"screenshot {name} exists but the checklist status is '{cells[6]}'")
        else:
            pending.append(name)
            if status == "captured":
                errors.append(f"checklist marks {name} Captured but screenshots/{folder}/{name} does not exist")
            elif name in on_disk:
                errors.append(f"screenshot {name} is in {rel(on_disk[name].parent)}, expected screenshots/{folder}")
    for name in sorted(set(on_disk) - listed):
        warnings.append(f"screenshot not in the checklist: {rel(on_disk[name])}")
    return captured, pending


def main():
    errors, warnings = [], []
    links = check_links(errors)
    check_readme(errors)
    jsons = check_json(errors)
    check_secrets(errors, warnings)
    captured, pending = check_screenshots(errors, warnings)

    print(f"Relative links checked: {links}")
    print(f"JSON files checked:     {jsons}")
    print(f"Screenshots captured:   {len(captured)} of {len(captured) + len(pending)}")
    for name in pending:
        print(f"  [ ] {name}")
    for name in captured:
        print(f"  [x] {name}")
    for w in warnings:
        print(f"WARNING: {w}")
    for e in errors:
        print(f"ERROR: {e}")
    print("FAILED" if errors else "OK")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
