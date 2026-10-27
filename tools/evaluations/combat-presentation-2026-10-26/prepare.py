from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    baseline_path = HERE / "baseline.json"
    if not baseline_path.exists():
        names = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT).decode().split("\0")
        files = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
                 for name in sorted(set(filter(None, names)))
                 if (ROOT / name).is_file() and not (ROOT / name).is_relative_to(HERE)}
        baseline_path.write_text(json.dumps({"started_utc": "2026-10-27T05:05:09Z",
                                             "deadline_utc": "2026-10-27T07:05:09Z",
                                             "recorded_utc": datetime.now(timezone.utc).isoformat(),
                                             "files": files,
                                             "git_status": subprocess.check_output(["git", "status", "--short"], cwd=ROOT).decode()}, indent=2) + "\n")
    assets = HERE / "assets"
    assets.mkdir(exist_ok=True)
    source = ROOT / "apps/monstrous_sea/assets/art"
    for original, target in (("ship_standard_map.png", "ship.png"), ("monster_serpent_map.png", "monster.png")):
        shutil.copy2(source / original, assets / target)
    shutil.copy2(Path("C:/Windows/Fonts/segoeui.ttf"), assets / "font.ttf")
    shutil.copy2(assets / "font.ttf", HERE / "flutter/assets/font.ttf")
    print(json.dumps({"assets": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in assets.iterdir()},
                      "preservation_files": len(json.loads(baseline_path.read_text())["files"])}, indent=2))


if __name__ == "__main__":
    main()
