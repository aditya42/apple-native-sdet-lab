import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

history = load("history", "failure-history/history.py")
parser = load("result_parser", "xcresult-parser/parse_xcresult.py")
gate = load("performance_gate", "performance/check_thresholds.py")

class ReportingTests(unittest.TestCase):
    def test_history_idempotency_and_flakiness(self):
        with tempfile.TemporaryDirectory() as tmp:
            with history.connect(Path(tmp) / "history.sqlite") as db:
                for i, status in enumerate(["passed", "failed", "passed", "failed", "passed"]):
                    record = {"bundle": str(i), "tests": [
                        {"test": "A", "status": status, "duration": 0.5}
                    ]}
                    self.assertTrue(history.ingest(db, record, f"run:{i}"))
                    self.assertFalse(history.ingest(db, record, f"run:{i}"))
                result = history.score(db)
                self.assertEqual(result[0]["samples"], 5)
                self.assertEqual(result[0]["classification"], "FLAKY")

    def test_xcresult_parser_preserves_passes(self):
        tree = {"testNodes": [{"nodeType": "Test Suite", "testNodes": [
            {"nodeType": "Test Case", "nodeIdentifier": "Suite/testA", "result": "Passed", "duration": 0.2},
            {"nodeType": "Test Case", "nodeIdentifier": "Suite/testB", "result": "Failed", "duration": 0.3}
        ]}]}
        rows = parser.normalized_tests(tree, [{"testName": "testB", "failureText": "assertion failed"}])
        self.assertEqual([r["status"] for r in rows], ["passed", "failed"])

    def test_performance_gate(self):
        issues, checked = gate.evaluate(
            {"tests": [{"test": "Suite/search", "status": "passed", "duration": 2.1}]},
            {"search": {"maxDurationSeconds": 2.0}}
        )
        self.assertEqual(checked, 1)
        self.assertEqual(len(issues), 1)

if __name__ == "__main__":
    unittest.main()
