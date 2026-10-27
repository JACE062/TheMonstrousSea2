"""Audit the saved evidence and preservation boundary before ending this goal."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    baseline = json.loads((HERE / "baseline.json").read_text())
    changed = [name for name, digest in baseline["files"].items()
               if not (ROOT / name).is_file()
               or hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest]
    current_paths = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT
    ).decode().split("\0")
    outside = {name for name in current_paths if name and not (ROOT / name).is_relative_to(HERE)}
    added_outside = sorted(outside - set(baseline["files"]))
    assert not changed and not added_outside, (changed, added_outside)
    provenance = json.loads((HERE / "download.json").read_text())
    assert provenance["checksum_verified"] is True
    archive = HERE / "runtime/Godot_v4.7.2-stable_win64.exe.zip"
    assert hashlib.sha512(archive.read_bytes()).hexdigest() == provenance["sha512"]
    for name in ("ship_standard_map.png", "monster_serpent_map.png"):
        assert (HERE / "project/assets" / name).read_bytes() == (ROOT / "apps/monstrous_sea/assets/art" / name).read_bytes()
    runs = {}
    for name in ("isolated", "modified-shortpath", "relaunch-shortpath", "final-check"):
        receipt = json.loads((HERE / "evidence" / name / "verified.json").read_text())
        assert receipt["process_exit_code"] == 0 and receipt["stderr"] == "", receipt
        assert receipt["before"]["display_driver"] == "Windows", receipt
        assert receipt["after"]["ship_x"] == 420 and receipt["after"]["bearing"] == "Short", receipt
        assert receipt["after"]["health_bar"] == receipt["after"]["hull"], receipt
        for image_name in ("before.png", "after.png"):
            payload = (HERE / "evidence" / name / image_name).read_bytes()
            assert payload[:8] == b"\x89PNG\r\n\x1a\n"
            assert struct.unpack(">II", payload[16:24]) == (1000, 620)
            assert len(payload) > 10000
        runs[name] = {"duration_seconds": receipt["duration_seconds"],
                      "hull_after": receipt["after"]["hull"],
                      "revision": receipt["after"]["revision"]}
    assert runs["isolated"]["hull_after"] == 92
    assert runs["modified-shortpath"]["hull_after"] == 87
    initial_data_path = Path("C:/Users/jcarvajal/AppData/Roaming/Godot/app_userdata/Monstrous Sea Godot Feasibility")
    assert not initial_data_path.exists(), initial_data_path
    source = (HERE / "project/main.gd").read_text()
    assert "get_viewport().get_texture().get_image()" in source
    assert 'server.listen(0, "127.0.0.1")' in source
    assert "damage_per_test = 13" in (HERE / "project/main.tscn").read_text()
    # Check the report's relative links; this evaluation stays outside the current gameplay reference set.
    report = (HERE / "README.md").read_text()
    for target in re.findall(r"!?\[[^\]]*\]\(([^\n)]+)\)", report):
        if "://" not in target and target != "completion.json":
            assert (HERE / target).exists(), target
    now = datetime.now(timezone.utc)
    start = datetime.fromisoformat(baseline["started_utc"].replace("Z", "+00:00"))
    deadline = datetime.fromisoformat(baseline["deadline_utc"].replace("Z", "+00:00"))
    assert now < deadline, "Goal deadline reached before completion audit"
    result = {"status": "feasibility requirements verified; comparative phase not started",
              "started_utc": baseline["started_utc"], "audit_completed_utc": now.isoformat(),
              "elapsed_seconds": round((now - start).total_seconds(), 1),
              "deadline_utc": baseline["deadline_utc"], "within_45_minutes": True,
              "pre_existing_files_unchanged": len(baseline["files"]),
              "files_added_outside_evaluation": added_outside,
              "official_archive_checksum_verified": True, "approved_art_byte_identical": True,
              "initial_external_cache_removed": True, "successful_runs": runs,
              "manual_editor_interventions": 0,
              "scope_limits": ["No comparison to Flutter", "No rules migration", "No C# or export test",
                               "No native mouse/keyboard input test", "No full OS filesystem trace"]}
    (HERE / "completion.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
