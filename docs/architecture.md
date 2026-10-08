# Architecture

```mermaid
flowchart TD
  GA[GitHub Actions] --> ORCH[Test Orchestration]
  ORCH --> UT[XCTest Unit / Integration]
  ORCH --> UI[XCUITest]
  ORCH --> PERF[XCTest Performance]
  UI --> LIFE[Lifecycle Tests]
  UI --> ACC[Accessibility Contract]
  UI --> APP[ContactLab]
  UT --> APP
  PERF --> APP
  APP --> CD[CoreData]
  APP --> API[URLSession API Client]
  API --> MOCK[Controllable Mock HTTP Server]
  MOCK --> FI[Latency / 500 / 503 / malformed / timeout]
  ORCH --> XCR[.xcresult]
  XCR --> PARSER[XCResult Parser]
  PARSER --> CLASS[Failure Classifier]
  CLASS --> REPORT[HTML / JSON Report]
```

## Testability contract

The app exposes deterministic test hooks only through launch arguments and environment variables:

- `--uitesting`
- `--reset-data`
- `--in-memory-store`
- `CONTACT_API_BASE_URL`

UI automation selects controls through stable accessibility identifiers rather than localized visible text wherever practical.
