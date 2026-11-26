# README next increments

This document records the eight additions and their verification methods.

| Increment | Implementation | Verification |
| --- | --- | --- |
| Retry then success | MockServer `retry_then_success`; URLSession bounded retries | `APIClientResilienceTests` |
| Deterministic offline | Test-only `OfflineURLProtocol`; injected URLSession | `OfflineModeUITests` |
| Locale and RTL | `TEST_LOCALE` runner parameter; Arabic UI test | `LocalizationUITests` |
| VoiceOver readiness | Semantic labels and stable accessibility identifiers | `AccessibilityContractTests` |
| Performance limits | Configurable per-test budgets | `Tools/performance/check_thresholds.py` |
| SQLite results | Deduplicated test outcomes and run timestamps | `Tools/failure-history/history.py` |
| Flakiness scores | Failure and transition rates, confidence bound | `Tools/tests/test_reporting.py` |
| Test shards | Unit/UI split on two iPhone simulators | PR workflow matrix |

## Commands

```bash
python3 -m unittest discover -s Tools/tests -v
make bootstrap
make domain-test
make mock
TEST_LOCALE=de_DE make test
make report
python3 Tools/failure-history/history.py --db reports/history.sqlite
python3 Tools/performance/check_thresholds.py reports/classified.json
```

## Boundaries

The accessibility assertions inspect labels, identifiers and tappability; they do not automate spoken VoiceOver output. Runtime thresholds currently measure total XCTest case durations rather than extracting individual launch/search metric samples. Set budgets from reproducible runner baselines before treating them as strict performance regression limits. SQLite history is local to each job unless persisted/restored using an external artifact store; uploaded CI artifacts alone do not automatically provide cross-run history. Simulator matrix coverage depends on installed Xcode runtimes. Actual iOS and XCUITest verification requires macOS with Xcode.
