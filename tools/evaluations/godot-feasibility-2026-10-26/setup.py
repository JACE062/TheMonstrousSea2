"""Prepare only this isolated evaluation; never launch the production app."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import urllib.request
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
VERSION = "4.7.2"
ARCHIVE = f"Godot_v{VERSION}-stable_win64.exe.zip"
DOWNLOAD = ("https://downloads.godotengine.org/?flavor=stable&platform=windows.64"
            f"&slug=win64.exe.zip&version={VERSION}")


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "MonstrousSea-Godot-Feasibility/1.0"})
    with urllib.request.urlopen(request, timeout=50) as response:
        return response.read(), response.url


def baseline():
    destination = HERE / "baseline.json"
    if destination.exists():
        return
    paths = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT
    ).decode().split("\0")
    files = {}
    for name in sorted(set(filter(None, paths))):
        path = ROOT / name
        if path.is_file() and not path.is_relative_to(HERE):
            files[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    record = {
        "started_utc": "2026-10-27T04:40:25Z",
        "deadline_utc": "2026-10-27T05:25:25Z",
        "baseline_recorded_utc": datetime.now(timezone.utc).isoformat(),
        "git_status": subprocess.check_output(["git", "status", "--short"], cwd=ROOT).decode(),
        "files": files,
    }
    destination.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"Recorded preservation baseline: {len(files)} files", flush=True)


def main():
    baseline()
    runtime = HERE / "runtime"
    runtime.mkdir(exist_ok=True)
    archive_path = runtime / ARCHIVE
    provenance_path = HERE / "download.json"
    if not archive_path.exists():
        print(f"Downloading official portable Godot {VERSION}", flush=True)
        payload, resolved = fetch(DOWNLOAD)
        archive_path.write_bytes(payload)
        provenance = {"requested_url": DOWNLOAD, "resolved_url": resolved,
                      "downloaded_utc": datetime.now(timezone.utc).isoformat(),
                      "bytes": len(payload), "sha256": hashlib.sha256(payload).hexdigest()}
        sums_url = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/SHA512-SUMS.txt"
        try:
            sums, _ = fetch(sums_url)
            (runtime / "SHA512-SUMS.txt").write_bytes(sums)
            expected = next(line.split()[0] for line in sums.decode().splitlines() if line.split()[-1].lstrip("*") == ARCHIVE)
            actual = hashlib.sha512(payload).hexdigest()
            if expected != actual:
                raise RuntimeError("Official SHA512 checksum mismatch")
            provenance.update(sha512=actual, checksum_url=sums_url, checksum_verified=True)
        except (OSError, StopIteration) as error:
            provenance.update(checksum_verified=False, checksum_issue=str(error))
        provenance_path.write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    with zipfile.ZipFile(archive_path) as archive:
        for item in archive.infolist():
            target = (runtime / item.filename).resolve()
            if not target.is_relative_to(runtime.resolve()):
                raise RuntimeError("Archive path leaves evaluation runtime")
        archive.extractall(runtime)
    # Portable self-contained mode keeps editor data with this downloaded binary.
    (runtime / "._sc_").touch()
    assets = HERE / "project" / "assets"
    assets.mkdir(parents=True, exist_ok=True)
    for name in ("ship_standard_map.png", "monster_serpent_map.png"):
        shutil.copy2(ROOT / "apps/monstrous_sea/assets/art" / name, assets / name)
    print(json.dumps(json.loads(provenance_path.read_text()), indent=2), flush=True)
    print("Portable executables: " + ", ".join(p.name for p in runtime.glob("*.exe")), flush=True)


if __name__ == "__main__":
    main()
