"""Run isolated native Windows Godot capture. No production engine/save imports."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import time

HERE = Path(__file__).resolve().parent
SHARED = HERE.parent
EXE = SHARED.parent / "godot-feasibility-2026-10-26/runtime/Godot_v4.7.2-stable_win64_console.exe"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run", default="revised")
    args = parser.parse_args()
    output = SHARED / "evidence/godot" / args.run
    output.mkdir(parents=True, exist_ok=True)
    if (output / "trace.json").exists():
        raise RuntimeError("Use a fresh run label to preserve prior capture evidence")
    environment = os.environ.copy()
    environment["APPDATA"] = str(HERE / "profile/roaming")
    environment["LOCALAPPDATA"] = str(HERE / "profile/local")
    for key in ("APPDATA", "LOCALAPPDATA"):
        Path(environment[key]).mkdir(parents=True, exist_ok=True)
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    command = [str(EXE), "--path", str(HERE), "--rendering-method", "gl_compatibility",
               "--audio-driver", "Dummy", "--position", "-10000,-10000", "--",
               f"--output-dir={output.as_posix()}"]
    started = time.monotonic()
    started_utc = datetime.now(timezone.utc).isoformat()
    (output / "command.json").write_text(json.dumps(command, indent=2) + "\n")
    with (output / "stdout.log").open("w", encoding="utf-8") as stdout, (output / "stderr.log").open("w", encoding="utf-8") as stderr:
        process = subprocess.Popen(command, cwd=HERE, env=environment, stdout=stdout,
                                   stderr=stderr, startupinfo=startup,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            code = process.wait(timeout=180)
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)
    receipt = {"started_utc": started_utc, "completed_utc": datetime.now(timezone.utc).isoformat(),
               "capture_wall_seconds": round(time.monotonic() - started, 3),
               "exit_code": code, "run": args.run, "command": command,
               "native_window": True, "headless": False,
               "manual_editor_work": "None", "production_saves_accessed": False}
    (output / "launch.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt, indent=2))
    if code:
        raise RuntimeError((output / "stderr.log").read_text())


if __name__ == "__main__":
    main()
