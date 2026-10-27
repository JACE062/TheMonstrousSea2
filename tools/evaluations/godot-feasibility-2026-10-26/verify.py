"""Launch real Godot rendering and inspect/control this fixture over loopback.

No production imports, process attachment, OS input automation, or save access.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
EXE = HERE / "runtime/Godot_v4.7.2-stable_win64_console.exe"


def request(port, operation, **fields):
    with socket.create_connection(("127.0.0.1", port), timeout=10) as connection:
        connection.settimeout(10)
        connection.sendall((json.dumps({"operation": operation, **fields}) + "\n").encode())
        chunks = bytearray()
        while b"\n" not in chunks:
            chunk = connection.recv(65536)
            if not chunk:
                raise RuntimeError("Runtime disconnected before a complete response")
            chunks.extend(chunk)
        response = json.loads(chunks.split(b"\n", 1)[0])
        if "error" in response:
            raise RuntimeError(response["error"])
        return response


def verify_preservation():
    baseline = json.loads((HERE / "baseline.json").read_text())
    changed = []
    for name, expected in baseline["files"].items():
        path = ROOT / name
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            changed.append(name)
    if changed:
        raise AssertionError(f"Existing files changed during evaluation: {changed}")
    return {"baseline_files_unchanged": len(baseline["files"])}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run", default=f"check-{time.time_ns()}")
    parser.add_argument("--expected-damage", type=int, default=13)
    parser.add_argument("--expected-revision", default="source revision 2")
    args = parser.parse_args()
    output = HERE / "evidence" / args.run
    if (output / "ready.json").exists():
        raise RuntimeError("Use a fresh --run label to avoid accepting stale runtime evidence")
    output.mkdir(parents=True, exist_ok=True)
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0  # Hidden helper launch; actual rendering remains enabled.
    command = [str(EXE), "--path", str(HERE / "project"), "--rendering-method", "gl_compatibility",
               "--audio-driver", "Dummy", "--position", "-10000,-10000", "--",
               f"--output-dir={output.as_posix()}"]
    environment = os.environ.copy()
    environment["APPDATA"] = str(HERE / "profile/roaming")
    environment["LOCALAPPDATA"] = str(HERE / "profile/local")
    Path(environment["APPDATA"]).mkdir(parents=True, exist_ok=True)
    Path(environment["LOCALAPPDATA"]).mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    (output / "command.json").write_text(json.dumps(command, indent=2) + "\n")
    with (output / "stdout.log").open("w", encoding="utf-8") as stdout, (output / "stderr.log").open("w", encoding="utf-8") as stderr:
        process = subprocess.Popen(command, cwd=HERE, stdout=stdout, stderr=stderr,
                                   startupinfo=startup, creationflags=subprocess.CREATE_NO_WINDOW,
                                   env=environment)
        try:
            deadline = time.monotonic() + 30
            while not (output / "ready.json").exists():
                if process.poll() is not None:
                    raise RuntimeError(f"Godot exited before readiness: {process.returncode}")
                if time.monotonic() > deadline:
                    raise TimeoutError("Godot readiness exceeded 30 seconds")
                time.sleep(0.1)
            ready = json.loads((output / "ready.json").read_text())
            port = ready["port"]
            before = request(port, "snapshot")
            assert before["revision"] == args.expected_revision, before
            assert before["damage_per_test"] == args.expected_damage, before
            assert before["hull"] == 100 and before["health_bar"] == 100, before
            assert before["ship_x"] == 270 and before["bearing"] == "Medium", before
            assert before["display_driver"] != "headless", before
            assert Path(before["user_data_dir"]).resolve().is_relative_to(HERE), before
            before_capture = request(port, "capture", label="before")
            assert before_capture["capture_result"] == 0, before_capture
            assert before_capture["image_width"] == 1000 and before_capture["image_height"] == 620, before_capture
            request(port, "advance")
            observations = []
            deadline = time.monotonic() + 5
            while True:
                state = request(port, "snapshot")
                observations.append(state)
                if not state["moving"]:
                    break
                if time.monotonic() > deadline:
                    raise TimeoutError("Movement did not complete")
                time.sleep(0.06)
            assert any(270 < state["ship_x"] < 420 for state in observations), observations
            assert state["ship_x"] == 420 and state["bearing"] == "Short", state
            after = request(port, "damage")
            assert after["hull"] == 100 - args.expected_damage, after
            assert after["health_bar"] == after["hull"], after
            assert after["health_label"] == f"Hull: {after['hull']} / 100", after
            after_capture = request(port, "capture", label="after")
            assert after_capture["capture_result"] == 0, after_capture
            assert (output / "before.png").read_bytes() != (output / "after.png").read_bytes()
            request(port, "shutdown")
            process.wait(timeout=10)
            assert process.returncode == 0, process.returncode
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)
    errors = (output / "stderr.log").read_text(encoding="utf-8")
    assert "SCRIPT ERROR" not in errors and "ERROR:" not in errors, errors
    result = {"completed_utc": datetime.now(timezone.utc).isoformat(),
              "duration_seconds": round(time.monotonic() - started, 3), "run": args.run,
              "before": before, "after": after, "movement_observations": observations,
              "captures": [before_capture, after_capture], "process_exit_code": process.returncode,
              "stderr": errors, "preservation": verify_preservation()}
    (output / "verified.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"run": args.run, "passed": True, "duration_seconds": result["duration_seconds"],
                      "godot": before["godot"], "display_driver": before["display_driver"],
                      "hull_before": before["hull"], "hull_after": after["hull"],
                      "ship_x_before": before["ship_x"], "ship_x_after": after["ship_x"],
                      "samples_during_tween": len(observations), "preservation": result["preservation"]}, indent=2))


if __name__ == "__main__":
    main()
