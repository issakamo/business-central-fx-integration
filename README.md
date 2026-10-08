# Business Central FX Integration

Automated foreign exchange rate synchronization and an outbound API for Dynamics 365 Business Central.

## Business Problem

Businesses trading in multiple currencies need current exchange rates
in Business Central's Currency Exchange Rate table, but entering them
is usually a manual, easily forgotten task. Separately, Business
Central has no built-in way for an external system to check the
health of an integration without someone opening the Web Client.

## Solution

This extension retrieves live exchange rates from a real external API
and writes them into Business Central's native currency data, with
retry handling, audit logging, and safeguards against writing
incorrect financial data. It also exposes the integration history
through an outbound OData v4 API, so an external system can monitor
sync health on its own.

- **Interface-based connector architecture** (`FXI Exchange Rate
  Provider`): a live HTTP implementation and a fixed-data mock share
  one contract, so the sync logic and its automated tests never depend
  on the real network
- **Real external integration**: calls the free, keyless Frankfurter
  exchange rate API (ECB-sourced), not a simulated placeholder
- **Financial-data safeguards**: the base currency is always the
  company's local currency (LCY) from General Ledger Setup, blank or
  mismatched bases are refused, and rates are written through
  Business Central's own field validation
- **Resilient orchestration**: bounded retry, partial-success
  reporting when some currencies aren't set up in Business Central,
  and an audit log of every run, including failed runs
- **Configurable via a Setup page**: choose target currencies and the
  provider (live, or a fixed-data mock restricted to sandbox
  environments), enable or disable the integration, and trigger a sync
  on demand
- **Outbound OData v4 API**: the integration log is exposed as a
  read-only external endpoint
- **Automated test coverage**, plus a deliberately separate live test
  against the real API

## Architecture

See [docs/architecture.md](docs/architecture.md) for the reasoning
behind the interface design, the safeguards around financial data, the
real Business Central platform behaviors this project uncovered, and
an honestly documented verification gap in the outbound API.

## Technologies

- Microsoft Dynamics 365 Business Central (AL)
- AL `interface` types, `HttpClient`, `JsonArray` / `JsonToken`
- Visual Studio Code + AL Language extension
- Docker (local development container)
- [Frankfurter](https://frankfurter.dev): a free, keyless exchange rate API

## Project Structure

```
src/            Extension objects (tables, pages, codeunits, interfaces, permissions)
tests/          Automated test codeunits
docs/           Architecture and design documentation
```

## Key Features

| Feature | Objects |
|---|---|
| Connector abstraction | `FXI Exchange Rate Provider` (interface), `FXI Mock Exchange Rate Provider`, `FXI Frankfurter Rate Provider` |
| Sync orchestration | `FXI Exchange Rate Sync Mgt`, `FXI Integration Log` |
| Configuration | `FXI Integration Setup`, `FXI Target Currency` |
| Outbound API | `FXI Integration Log API` (OData v4) |
| Security | `FXI Integration User` permission set |

## Testing

Run the tests with the VS Code CodeLens or the AL Test Tool. The core
suite (the interface mock, sync orchestration, the LCY and blank-base
guards, and partial-success handling) runs fully offline. One extra
test calls the real Frankfurter API, and is meant to be run manually
rather than as part of routine automated verification. See
`docs/architecture.md`.

## Development Setup

Requires a local Business Central Docker container with outbound
`HttpClient` requests enabled for this extension. See
[docs/installation.md](docs/installation.md).

## Status

Complete. Project 3 of a 3-project Business Central portfolio, alongside
[business-central-warehouse-control](https://github.com/issakamo/business-central-warehouse-control)
and
[business-central-purchase-control](https://github.com/issakamo/business-central-purchase-control).