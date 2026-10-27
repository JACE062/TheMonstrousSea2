"""Retain byte-identical selected engine frames outside the ignored raw sequences."""
from pathlib import Path
import shutil

HERE = Path(__file__).resolve().parent
for engine, run, speed in (("flutter", "baseline", 1), ("flutter", "revised-final", 2),
                           ("godot", "baseline", 1), ("godot", "revised", 2)):
    output = HERE / "evidence" / engine / run
    destination = output / "keyframes"
    destination.mkdir(exist_ok=True)
    for label, time_ms in (("start", 0), ("absorption", 5600), ("hull", 5800), ("burn-tick", 7800), ("final", 10000)):
        index = round(time_ms / 1000 * 30 / speed)
        shutil.copy2(output / "frames" / f"frame_{index:04d}.png", destination / f"{label}.png")
print("Selected engine frames copied without alteration.")
