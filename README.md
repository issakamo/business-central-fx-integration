# Business Central FX Integration

Automated foreign exchange rate synchronization and outbound API integration for Dynamics 365 Business Central.

## Business Problem

Businesses trading in multiple currencies need current exchange rates
in Business Central's own Currency Exchange Rate table, but populating
them is typically a manual, easily-forgotten task. Separately,
Business Central has no built-in way for an external system to check
on the health of an integration without a person opening the Web
Client.

## Solution

This extension automatically retrieves live exchange rates from a real
external API and writes them into Business Central's native currency
data, with full retry handling, audit logging, and a safety guard
against writing incorrect financial data. It also exposes that
integration history through a genuine outbound OData v4 API, so an
external system can monitor sync health on its own.

- **Interface-based connector architecture** (`FXI Exchange Rate
  Provider`) — a live HTTP-calling implementation and a fixed-data mock
  share one contract, so the sync logic, and its automated tests, never
  depend on the real network
- **Real external integration** — calls the free, keyless Frankfurter
  exchange rate API (ECB-sourced), not a simulated placeholder
- **Financial-data safety guard** — refuses to sync unless the
  configured base currency matches the company's actual local currency
  (LCY), since Business Central's Currency Exchange Rate table only
  makes sense relative to LCY
- **Resilient orchestration** — bounded retry, partial-success
  reporting when some currencies aren't set up in Business Central,
  and a full audit log of every run
- **Configurable via a Setup page** — choose the provider (live or
  mock), base currency, and target currencies; trigger a sync on
  demand
- **Outbound OData v4 API** — the integration log itself is exposed as
  a read-only external endpoint
- **Automated test coverage**, including a deliberately environment-
  dependent live test against the real API, kept separate from the
  core offline suite

## Architecture

See [docs/architecture.md](docs/architecture.md) for the reasoning
behind the interface design, the real Business Central platform
behaviors this project uncovered, and an honestly documented
verification gap in the outbound API.

## Technologies

- Microsoft Dynamics 365 Business Central (AL)
- AL `interface` types, `HttpClient`, `JsonArray`/`JsonToken`
- Visual Studio Code + AL Language extension
- Docker (local development container)
- [Frankfurter](https://frankfurter.dev) — free, keyless exchange rate API

## Project Structure

src/ Extension objects (tables, pages, codeunits, interfaces, permissions)
test/ Automated test codeunits
docs/ Architecture and design documentation


## Key Features

| Feature | Objects |
|---|---|
| Connector abstraction | `FXI Exchange Rate Provider` (interface), `FXI Mock Exchange Rate Provider`, `FXI Frankfurter Rate Provider` |
| Sync orchestration | `FXI Exchange Rate Sync Mgt`, `FXI Integration Log` |
| Configuration | `FXI Integration Setup`, `FXI Target Currency` |
| Outbound API | `FXI Integration Log API` (OData v4) |
| Security | `FXI Integration User` permission set |

## Testing

Run via VS Code CodeLens or the AL Test Tool. The core suite (interface
mock, sync orchestration, LCY guard, partial-success handling) runs
fully offline. One additional test calls the real Frankfurter API and
is meant to be run manually, not as part of routine automated
verification — see `docs/architecture.md`.

## Development Setup

Requires a local Business Central Docker container with outbound
`HttpClient` requests enabled for this extension. See
[docs/installation.md](docs/installation.md).

## Status

Actively in development — Project 3 of a 3-project portfolio, alongside
[business-central-warehouse-control](https://github.com/issakamo/business-central-warehouse-control)
and
[business-central-purchase-control](https://github.com/issakamo/business-central-purchase-control).
