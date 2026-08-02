# Context

Domain glossary for task-management-system. See `docs/adr/` for recorded architectural decisions.

## Store module

A module giving exclusive, single-seam access to one Firestore collection — narrow interface (`create`/`update`/`delete`/`fetch`/`stream`), model-owned validation, a Firestore adapter and an in-memory test adapter behind the seam, registered via `Provider`. Whether `fetch`/`stream` take query parameters is a per-`Store` choice, not a requirement. See [ADR-0001](docs/adr/0001-store-modules-for-firestore-collections.md).

Current instances: `TaskStore` (tasks collection, parameterized `fetch`/`stream`), `ProjectStore` (projects collection, parameterless `fetch`/`stream` — caller filters locally), `TeamStore` (teams collection — `create`/`update`/`delete`/`fetch`; no `stream`, added on demand like the others).
