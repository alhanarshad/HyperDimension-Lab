"""Compare elapsed travel time along two recordings of the same course."""
import argparse
import csv
import json
import math
from bisect import bisect_right
from pathlib import Path


def read_trace(path):
    with Path(path).open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if not {"elapsed_s", "distance_m"}.issubset(reader.fieldnames or []):
            raise ValueError(f"{path}: expected elapsed_s and distance_m columns")
        points = []
        for line, row in enumerate(reader, 2):
            try:
                elapsed, distance = float(row["elapsed_s"]), float(row["distance_m"])
            except (ValueError, TypeError) as exc:
                raise ValueError(f"{path}:{line}: invalid numeric sample") from exc
            if not all(math.isfinite(number) and number >= 0 for number in (elapsed, distance)):
                raise ValueError(f"{path}:{line}: samples must be nonnegative and finite")
            if points and (elapsed <= points[-1][1] or distance < points[-1][0]):
                raise ValueError(f"{path}:{line}: time must advance and distance cannot decrease")
            points.append((distance, elapsed))
    if len(points) < 2 or points[0][0] >= points[-1][0]:
        raise ValueError(f"{path}: expected at least two distinct distances")
    return points


def crossing(trace, distance):
    index = bisect_right(trace, (distance, math.inf))
    if index == 0:
        raise ValueError("Split precedes the trace")
    left, t0 = trace[index - 1]
    if left == distance:
        first = bisect_right(trace, (distance, -math.inf))
        return trace[first][1]
    if index == len(trace):
        raise ValueError("Split exceeds the trace")
    right, t1 = trace[index]
    return t0 + (t1 - t0) * (distance - left) / (right - left)


def compare(reference, candidate, step):
    if not math.isfinite(step) or step <= 0:
        raise ValueError("The split interval must be positive and finite")
    start = max(reference[0][0], candidate[0][0])
    finish = min(reference[-1][0], candidate[-1][0])
    if start >= finish:
        raise ValueError("The recordings must overlap along the course")
    count = (finish - start) / step
    if not math.isfinite(count) or count > 10000:
        raise ValueError("Choose an interval that produces at most 10,000 splits")
    r0, c0 = crossing(reference, start), crossing(candidate, start)
    sectors = []
    prev_r, prev_c = r0, c0
    number_of_splits = max(1, math.ceil(count))
    for index in range(1, number_of_splits + 1):
        distance = finish if index == number_of_splits else min(start + step * index, finish)
        r, c = crossing(reference, distance), crossing(candidate, distance)
        sectors.append({"distance_m": round(distance, 5),
                        "reference_s": round(r - r0, 5), "candidate_s": round(c - c0, 5),
                        "delta_s": round((c - c0) - (r - r0), 5),
                        "sector_delta_s": round((c - prev_c) - (r - prev_r), 5)})
        prev_r, prev_c = r, c
    return {"start_m": start, "finish_m": finish, "delta_s": sectors[-1]["delta_s"], "splits": sectors}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference")
    parser.add_argument("candidate")
    parser.add_argument("--step", type=float, default=100.0, help="Meters per sector")
    args = parser.parse_args()
    try:
        result = compare(read_trace(args.reference), read_trace(args.candidate), args.step)
    except (OSError, ValueError) as error:
        parser.exit(2, f"split-telemetry: {error}\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
