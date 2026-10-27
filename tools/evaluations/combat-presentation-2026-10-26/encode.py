"""Encode actual engine-rendered frames; no synthesized game imagery."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "runtime/python"))
import imageio_ffmpeg


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("engine", choices=["flutter", "godot"])
    parser.add_argument("run")
    args = parser.parse_args()
    output = HERE / "evidence" / args.engine / args.run
    frames = sorted((output / "frames").glob("frame_*.png"))
    if not frames:
        raise RuntimeError(f"No rendered frames: {output}")
    assert all(p.name == f"frame_{i:04d}.png" for i, p in enumerate(frames)), "Frame sequence must be contiguous"
    executable = imageio_ffmpeg.get_ffmpeg_exe()
    video = output / "recording.mp4"
    command = [executable, "-hide_banner", "-loglevel", "error", "-y", "-framerate", "30",
               "-i", str(output / "frames/frame_%04d.png"), "-c:v", "libx264", "-crf", "18",
               "-preset", "fast", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(video)]
    subprocess.run(command, check=True, capture_output=True, text=True, timeout=60)
    # Decode all the encoded frames as an independent container/codec sanity check.
    reader = imageio_ffmpeg.read_frames(str(video), pix_fmt="rgb24")
    metadata = next(reader)
    decoded_count = sum(1 for _ in reader)
    assert decoded_count == len(frames), (decoded_count, len(frames))
    assert tuple(metadata["size"]) == (1000, 620), metadata
    assert abs(metadata["fps"] - 30) < 0.01, metadata
    result = {"engine": args.engine, "run": args.run, "source_frames": len(frames),
              "decoded_frames": decoded_count, "video_bytes": video.stat().st_size,
              "video_sha256": hashlib.sha256(video.read_bytes()).hexdigest(),
              "fps": metadata["fps"], "size": metadata["size"], "duration_seconds": metadata["duration"],
              "encoder": subprocess.check_output([executable, "-version"], text=True).splitlines()[0],
              "command": command}
    (output / "encoding.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({key: value for key, value in result.items() if key != "command"}, indent=2))


if __name__ == "__main__":
    main()
