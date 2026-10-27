"""Independent comparison of displayed engine state to the shared fixture."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

from oracle import FIXTURE, expected_state

HERE = Path(__file__).resolve().parent


def audit(engine, run, speed, barrier_delay):
    output = HERE / "evidence" / engine / run
    trace = json.loads((output / "trace.json").read_text())
    assert trace["fixture_sha256"] == hashlib.sha256((HERE / "fixture.json").read_bytes()).hexdigest()
    assert abs(trace["speed"] - speed) < 0.001, trace["speed"]
    frames = trace["frames"]
    expected_count = round(FIXTURE["duration_ms"] / 1000 * 30 / speed) + 1
    assert len(frames) == expected_count, (len(frames), expected_count)
    hashes = set()
    markers = set()
    moving_samples = 0
    for index, state in enumerate(frames):
        time_ms = state.get("time_ms", state.get("logical_time_ms"))
        assert time_ms is not None, state.keys()
        assert abs(time_ms - index * 1000 / 30 * speed) < 0.01, (index, time_ms)
        expected = expected_state(time_ms, barrier_delay)
        for field in ("ship_hp", "monster_hp", "barrier", "burn", "bearing"):
            assert state[field] == expected[field], (engine, run, index, time_ms, field, state[field], expected[field])
        if 800 < time_ms < 1450:
            assert 270 < state["ship_x"] < 420, state
            moving_samples += 1
        else:
            assert abs(state["ship_x"] - expected["ship_x"]) < 0.01, state
        for who in ("ship", "monster"):
            ratio = state.get(f"{who}_hp_bar")
            if ratio is not None:
                assert abs(ratio - state[f"{who}_hp"] / FIXTURE["initial"][f"{who}_max_hp"]) < 0.001, state
        hud = state.get("displayed_hud")
        if hud is not None:
            for who in ("ship", "monster"):
                assert [int(value) for value in re.findall(r"\d+", hud[f"{who}_hp_label"])] == [state[f"{who}_hp"], FIXTURE["initial"][f"{who}_max_hp"]], state
                assert abs(hud[f"{who}_hp_bar"] - state[f"{who}_hp"] / FIXTURE["initial"][f"{who}_max_hp"]) < 0.001, state
            assert hud["barrier_label"] == f"Barrier: {state['barrier']}", state
            assert bool(hud["burn_label"]) == state["burn"], state
            assert hud["bearing_label"] == f"Bearing: {state['bearing']}", state
        markers.update(state.get("observed_event_markers", state.get("event_markers", [])))
        image_path = output / "frames" / f"frame_{index:04d}.png"
        image = image_path.read_bytes()
        assert image[:8] == b"\x89PNG\r\n\x1a\n", image_path
        assert struct.unpack(">II", image[16:24]) == (1000, 620), image_path
        assert len(image) > 10000, image_path
        hashes.add(hashlib.sha256(image).hexdigest())
    markers.update(trace.get("observed_event_markers", trace.get("event_markers", [])))
    original_markers = {e["id"] for e in FIXTURE["events"]}
    allowed_phase_markers = {f"{e['id']}_hull" for e in FIXTURE["events"] if e["type"] == "ship_hit" and e["absorbed"] > 0} if barrier_delay else set()
    assert original_markers <= markers and markers <= original_markers | allowed_phase_markers, markers
    assert moving_samples > 2
    assert len(hashes) > 30, "Recorded imagery did not meaningfully change"
    result = {"independent_audit_passed": True, "engine": engine, "run": run,
              "frames_checked": len(frames), "unique_rendered_frames": len(hashes),
              "movement_samples": moving_samples, "fixture_events_verified": sorted(markers),
              "speed": speed, "barrier_hull_delay_ms": barrier_delay,
              "last_logical_time_ms": frames[-1].get("time_ms", frames[-1].get("logical_time_ms")),
              "final_state": {k: frames[-1][k] for k in FIXTURE["final"]},
              "method": "Every displayed-state sample checked against parent-owned oracle and contiguous real PNGs; animation easing not fixed"}
    (output / "independent-audit.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("engine", choices=["flutter", "godot"])
    parser.add_argument("run")
    parser.add_argument("--speed", type=float, default=1)
    parser.add_argument("--barrier-delay", type=float, default=0)
    args = parser.parse_args()
    print(json.dumps(audit(args.engine, args.run, args.speed, args.barrier_delay), indent=2))
