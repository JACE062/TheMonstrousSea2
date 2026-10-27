"""Expected presentation facts, independently evaluated outside either renderer."""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
FIXTURE = json.loads((HERE / "fixture.json").read_text())


def expected_state(time_ms, barrier_delay_ms=0):
    state = dict(FIXTURE["initial"])
    for event in FIXTURE["events"]:
        age = time_ms - event["at_ms"]
        if age < -0.001:
            continue
        kind = event["type"]
        if kind == "movement":
            progress = min(1, max(0, age / event["duration_ms"]))
            # Only endpoints are normative: an engine may choose an easing curve.
            state["ship_x"] = event["from_x"] + progress * (event["to_x"] - event["from_x"])
            if progress >= 1:
                state["bearing"] = event["bearing_after"]
        elif kind == "monster_damage":
            state["monster_hp"] = event["monster_hp_after"]
        elif kind == "barrier_granted":
            state["barrier"] = event["barrier_after"]
        elif kind == "status_applied":
            state["burn"] = True
        elif kind == "ship_hit":
            state["barrier"] = event["barrier_after"]
            delay = barrier_delay_ms if event["absorbed"] > 0 else 0
            if age + 0.001 >= delay:
                state["ship_hp"] = event["ship_hp_after"]
        elif kind == "status_tick":
            state["ship_hp"] = event["ship_hp_after"]
        elif kind == "status_expired":
            state["burn"] = False
    return state


if __name__ == "__main__":
    for sample in [0, 1450, 2000, 3000, 3800, 4800, 5500, 5600, 5740, 6200, 6900, 7800, 8500, 10000]:
        print(json.dumps({"time_ms": sample, "baseline": expected_state(sample), "revised": expected_state(sample, 240)}))
