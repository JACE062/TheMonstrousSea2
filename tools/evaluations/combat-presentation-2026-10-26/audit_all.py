"""Final evidence/preservation audit; deliberately separate from both engines."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

from audit_run import audit

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    baseline = json.loads((HERE / "baseline.json").read_text())
    changes = [name for name, expected in baseline["files"].items()
               if not (ROOT / name).is_file()
               or hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != expected]
    assert not changes, changes
    names = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT).decode().split("\0")
    added_outside = [name for name in names if name and name not in baseline["files"] and not (ROOT / name).is_relative_to(HERE)]
    assert not added_outside, added_outside
    receipts = []
    trace_sets = {}
    for engine in ("flutter", "godot"):
        for run, speed, delay in (("baseline", 1, 0), ("revised", 2, 240)):
            evidence_run = "revised-final" if engine == "flutter" and run == "revised" else run
            receipts.append(audit(engine, evidence_run, speed, delay))
            directory = HERE / "evidence" / engine / evidence_run
            encoding = json.loads((directory / "encoding.json").read_text())
            video = directory / "recording.mp4"
            assert video.is_file() and video.stat().st_size == encoding["video_bytes"]
            assert hashlib.sha256(video.read_bytes()).hexdigest() == encoding["video_sha256"]
            assert encoding["decoded_frames"] == receipts[-1]["frames_checked"]
            trace_sets[engine, run] = json.loads((directory / "trace.json").read_text())["frames"]
            assert (directory / "source").is_dir(), directory
            if run == "revised":
                assert (directory / "maintenance.patch").is_file(), directory
                for frame in trace_sets[engine, run]:
                    assert "-0 hull" not in frame.get("impact_text", ""), frame
                    assert all("-0 hull" not in item["text"] for item in frame.get("visible_feedback", [])), frame
    for run in ("baseline", "revised"):
        for flutter, godot in zip(trace_sets["flutter", run], trace_sets["godot", run], strict=True):
            for key in ("ship_hp", "monster_hp", "barrier", "burn", "bearing"):
                assert flutter[key] == godot[key], (run, key, flutter, godot)
            assert abs(flutter["ship_x"] - godot["ship_x"]) < 0.01
    source_assets = ROOT / "apps/monstrous_sea/assets/art"
    for name, original in (("ship.png", "ship_standard_map.png"), ("monster.png", "monster_serpent_map.png")):
        assert (HERE / "assets" / name).read_bytes() == (source_assets / original).read_bytes()
        assert (HERE / "flutter/assets" / name).read_bytes() == (HERE / "assets" / name).read_bytes()
    assert (HERE / "flutter/assets/font.ttf").read_bytes() == (HERE / "assets/font.ttf").read_bytes()
    assert (HERE / "flutter/assets/fixture.json").read_bytes() == (HERE / "fixture.json").read_bytes()
    now = datetime.now(timezone.utc)
    start = datetime.fromisoformat(baseline["started_utc"].replace("Z", "+00:00"))
    deadline = datetime.fromisoformat(baseline["deadline_utc"].replace("Z", "+00:00"))
    assert now < deadline, "Two-hour comparison limit exceeded"
    result = {"status": "comparison evidence and preservation verified", "started_utc": baseline["started_utc"],
              "completed_utc": now.isoformat(), "elapsed_seconds": round((now-start).total_seconds(), 1),
              "deadline_utc": baseline["deadline_utc"], "within_two_hours": True,
              "pre_existing_files_unchanged": len(baseline["files"]), "files_added_outside_evaluation": added_outside,
              "both_engines_match_every_displayed_state": True, "shared_assets_and_fixture_byte_identical": True,
              "recordings_encoded_and_decoded": 4, "total_displayed_frames_checked": sum(r["frames_checked"] for r in receipts),
              "runs": receipts,
              "scope_limits": ["Synthetic event playback; no rules port", "Fixed-size, fixed-step capture; no runtime FPS benchmark",
                               "No sound or native input test", "No full OS filesystem trace", "No engine migration or combat UI redesign"]}
    (HERE / "completion.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
