import tempfile
import unittest
from pathlib import Path

from split_telemetry import compare, crossing, read_trace


class SplitTelemetryTests(unittest.TestCase):
    def test_standing_at_gate(self):
        trace = [(0, 0), (100, 4), (100, 7), (200, 11)]
        self.assertEqual(crossing(trace, 100), 4)
        self.assertEqual(crossing(trace, 150), 9)

    def test_alignment_and_short_final_sector(self):
        report = compare([(0, 0), (10, 1), (40, 4)], [(10, 8), (40, 14)], 20)
        self.assertEqual([s["distance_m"] for s in report["splits"]], [30, 40])
        self.assertEqual([s["sector_delta_s"] for s in report["splits"]], [2, 1])
        self.assertEqual(report["delta_s"], 3)

    def test_step_and_overlap_validation(self):
        for step in (0, float("inf"), float("nan"), 1e-12):
            with self.assertRaises(ValueError):
                compare([(0, 0), (4, 4)], [(0, 0), (3, 3)], step)
        with self.assertRaises(ValueError):
            compare([(0, 0), (4, 4)], [(4, 0), (6, 3)], 1)

    def test_reader_rejects_backtracking(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "trace.csv"
            path.write_text("elapsed_s,distance_m\n0,0\n1,10\n2,5\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "distance cannot decrease"):
                read_trace(path)

    def test_extreme_interval_still_reports_finish(self):
        distance = 1e-200
        report = compare([(0, 0), (distance, 2)], [(0, 0), (distance, 3)], 1e200)
        self.assertEqual(len(report["splits"]), 1)
        self.assertEqual(report["delta_s"], 1)
