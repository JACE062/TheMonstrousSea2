"""Check current documentation links and the preserved migration evidence.

Run from any directory with Python 3.10+; this uses only the standard library
and does not modify files, game state, generated art, or Git.
"""

from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "docs/archive"
LINK = re.compile(r"!?\[[^\]]*\]\(([^\n)]+)\)")
ERRORS = []


def require(condition, message):
    if not condition:
        ERRORS.append(message)


def without_fences(text):
    lines = []
    fenced = False
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            fenced = not fenced
        elif not fenced:
            lines.append(line)
    return "\n".join(lines)


def headings(text):
    result = []
    for line in without_fences(text).splitlines():
        match = re.match(r"^(#{1,6}) (.+)$", line)
        if match:
            result.append((len(match[1]), match[2]))
    return result


def anchors(path):
    counts = Counter()
    result = set()
    for _, heading in headings(path.read_text(encoding="utf-8")):
        slug = re.sub(r"[^\w\- ]", "", heading.lower()).replace(" ", "-")
        count = counts[slug]
        counts[slug] += 1
        result.add(slug if count == 0 else f"{slug}-{count}")
    return result


def local_target(path, target):
    location, _, anchor = target.partition("#")
    if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", location):
        if location.startswith("file://"):
            require(False, f"{path.relative_to(ROOT)}: machine-specific file URI: {target}")
        return None, None
    destination = (path.parent / unquote(location)).resolve() if location else path
    return destination, unquote(anchor)


def check_links(files):
    count = 0
    for path in files:
        historical = path.is_relative_to(ARCHIVE)
        text = path.read_text(encoding="utf-8")
        if not historical:
            for line_number, line in enumerate(text.splitlines(), 1):
                require(line == line.rstrip(), f"{path.relative_to(ROOT)}:{line_number}: trailing whitespace")
        for match in LINK.finditer(without_fences(text)):
            destination, anchor = local_target(path, match[1])
            if destination is None:
                continue
            count += 1
            require(destination.is_relative_to(ROOT), f"{path.relative_to(ROOT)}: link leaves repository: {match[1]}")
            require(destination.exists(), f"{path.relative_to(ROOT)}: missing target: {match[1]}")
            if anchor and destination.is_file() and destination.suffix == ".md":
                require(anchor in anchors(destination), f"{path.relative_to(ROOT)}: missing heading: {match[1]}")
            if not historical and destination.is_relative_to(ARCHIVE):
                require(destination == ARCHIVE / "README.md", f"{path.relative_to(ROOT)}: active guidance directly links a historical instruction: {match[1]}")
    return count


def check_migration(manifest):
    section_count = 0
    for record in manifest["documents"]:
        source = record["source"]
        archive = ROOT / record["archive"]
        require(archive.is_relative_to(ARCHIVE), f"Archive outside historical directory: {source}")
        if not archive.is_file():
            require(False, f"Missing archive: {record['archive']}")
            continue
        text = archive.read_text(encoding="utf-8")
        warning, separator, body = text.partition("\n\n")
        require("HISTORICAL / SUPERSEDED" in warning and separator, f"Missing historical warning: {archive.name}")
        require(hashlib.sha256(body.encode()).hexdigest() == record["archive_body_sha256"], f"Historical body changed without a migration record: {archive.name}")
        require(headings(body) == [(s["level"], s["heading"]) for s in record["sections"]], f"Historical section coverage differs: {source}")
        original = subprocess.run(
            ["git", "show", f"{record['source_commit']}:{source}"],
            cwd=ROOT, check=True, capture_output=True,
        ).stdout
        require(hashlib.sha256(original).hexdigest() == record["source_sha256"], f"Source revision hash differs: {source}")
        require(headings(original.decode("utf-8")) == headings(body), f"Source headings were lost: {source}")
        if source != "CLAUDE.md":
            require(not (ROOT / source).exists(), f"Superseded original still appears active: {source}")
        for section in record["sections"]:
            section_count += 1
            require(section["disposition"] and section["reason"] and section["targets"], f"Unaccounted source section: {source}: {section['heading']}")
            for target in section["targets"]:
                destination, anchor = local_target(ROOT / "_manifest_root.md", target)
                require(destination is not None and destination.exists(), f"Missing disposition target: {target}")
                if destination and anchor and destination.is_file():
                    require(anchor in anchors(destination), f"Missing disposition heading: {target}")
    for name, expected in manifest["screenshots"].items():
        path = ROOT / name
        require(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == expected, f"Screenshot missing or altered: {name}")
    backlog = (ROOT / "docs/BACKLOG.md").read_text(encoding="utf-8")
    ids = re.findall(r"^### (PT2-\d{2}) ", backlog, re.M)
    counts = Counter(ids)
    require(all(counts[issue] == 1 for issue in manifest["backlog_ids"]), "Backlog must retain each original PT2 issue exactly once")
    require(all(count == 1 for count in counts.values()), "Backlog issue IDs must be unique, including follow-up issues")
    original_spec = next(r for r in manifest["documents"] if r["source"] == "docs/PHASE_3B_OCEAN_POWERS_SPEC.md")
    spec = (ROOT / original_spec["archive"]).read_text(encoding="utf-8")
    rows = [line for line in spec.splitlines() if line.startswith("| **")]
    require(len(rows) == 12, "Historical Phase 3B source is missing one of its twelve catalog rows")
    # The archive is evidence, never a permanent constraint on live balance.
    # Initial promotion fidelity is recorded at migration; future approved edits
    # to CURRENT_GAME must not be forced to reproduce historical numeric values.
    promotion = manifest["initial_catalog_promotion"]
    require(promotion["row_count"] == len(rows) and promotion["verified_exact_at_migration"], "Missing initial catalog-promotion receipt")
    root_pages = {p.name for p in (ROOT / "docs").glob("*.md")}
    require(root_pages == {"README.md", "CURRENT_GAME.md", "LORE.md", "BACKLOG.md"}, f"Unexpected competing top-level documentation: {sorted(root_pages)}")
    ignore = (ROOT / ".rgignore").read_text(encoding="utf-8").splitlines()
    require("docs/archive/" in ignore and "docs/art/archive/" in ignore, "Historical directories must remain excluded from routine ripgrep searches")
    return section_count


def main():
    manifest = json.loads((ARCHIVE / "migration_manifest.json").read_text(encoding="utf-8"))
    files = sorted((ROOT / "docs").rglob("*.md")) + [ROOT / "CLAUDE.md", ROOT / "AGENTS.md"]
    links = check_links(files)
    sections = check_migration(manifest)
    if ERRORS:
        for error in ERRORS:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    issue_count = len(re.findall(r"^### PT2-\d{2} ", (ROOT / "docs/BACKLOG.md").read_text(encoding="utf-8"), re.M))
    print(f"Documentation OK: {len(files)} Markdown files, {links} local links, {len(manifest['documents'])} archived sources / {sections} section dispositions, {issue_count} PT2 issues, catalog-promotion receipt, six unchanged original screenshots.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
