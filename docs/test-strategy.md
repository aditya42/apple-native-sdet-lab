# Test Strategy

## Layers

1. **Domain unit tests** — validation and search behavior.
2. **Persistence tests** — CoreData save/read/delete behavior.
3. **Networking tests** — URLSession response and error mapping.
4. **XCUITest workflows** — CRUD, search, lifecycle, accessibility contract.
5. **Performance** — search and launch metrics.
6. **Reliability** — repeated critical-path execution with pass-rate aggregation.
7. **Diagnostics** — screenshot + UI hierarchy attachments and xcresult normalization.

## Fault scenarios

Configure the mock service through `POST /test/scenario`:

- `normal`
- `empty`
- `server_error`
- `service_unavailable`
- `slow_3s`
- `timeout`
- `malformed_json`

Example:

```bash
curl -X POST http://127.0.0.1:8080/test/scenario \
  -H 'content-type: application/json' \
  -d '{"scenario":"server_error"}'
```
