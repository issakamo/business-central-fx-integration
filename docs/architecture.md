# Architecture & Design Decisions

This document explains *why* the extension is built the way it is,
including real Business Central platform behaviors and a genuine
unresolved environment issue encountered during development.

## Interface-Based Connector Design

`FXI Exchange Rate Provider` is an AL `interface` — a contract
(`GetRates`) with no implementation of its own. Two codeunits
`implements` it: `FXI Mock Exchange Rate Provider` (fixed, instant,
offline data) and `FXI Frankfurter Rate Provider` (a real `HttpClient`
call to Frankfurter). Every piece of orchestration logic
(`FXI Exchange Rate Sync Mgt.SyncRates`) is written against the
interface, never against either implementation by name — which of the
two actually runs is decided at the call site, either by a test
choosing the mock, or by the Setup page's `Provider` field choosing
either at runtime for a real user.

This solves a real, recurring problem this portfolio has faced
before: in Project 2, live-posting behavior inside an automated test
transaction differed from real Web Client behavior in a way that had
to be discovered and worked around after the fact. Here, the same
class of problem — "don't let automated tests depend on unpredictable
real-world behavior" — is addressed architecturally, up front, rather
than patched reactively: tests exercise the mock, never the network,
by construction.

Unlike this portfolio's earlier event-subscriber work (where a wrong
signature could fail silently at runtime, discovered only through
careful manual verification), a codeunit that `implements` an
interface incorrectly **fails to compile** — a real, immediate safety
net the event-subscriber pattern doesn't offer.

## Why Frankfurter, and What Calling It Revealed

Frankfurter (`api.frankfurter.dev`) was chosen as a free, keyless, real
financial data API — thematically apt, since Business Central has a
native `Currency Exchange Rate` table this data feeds directly.

Its actual v2 response shape was verified empirically before writing
any parsing code, and it differed from what documentation search
results initially suggested: **the response is a flat JSON array** of
`{date, base, quote, rate}` rows, not a single nested object
(`{"rates": {...}}`) as an older v1-style API might return. This was
confirmed with a direct browser request before committing to
`JsonArray`-based parsing, rather than trusting a search summary.

## Business Central Blocks Outbound HTTP by Default

The first live call to Frankfurter failed silently — `HttpClient.Get`
returning `false` with no further detail, for *any* external domain,
including an unrelated control endpoint (`api.github.com`) used
specifically to rule out a Frankfurter-specific cause. This was
eventually traced to a genuine, documented Business Central security
feature: **outbound `HttpClient` calls are blocked by default for
every extension** and must be explicitly enabled per-extension via
Extension Management → Configure → "Allow HttpClient Requests." This
is a deliberate anti-exfiltration safeguard, not a bug — worth knowing
as a first checkpoint for any BC extension that makes outbound calls
and appears to silently fail with no error detail at all.

## Financial Data Safety: the LCY Guard

Business Central's native `Currency Exchange Rate` table only stores
rates **relative to the company's local currency (LCY)** — a
`Currency Code` (foreign currency) paired with a blank
`Relational Currency Code` (implicitly LCY). It has no concept of an
arbitrary cross-rate between two foreign currencies without an
explicit relational currency being set up.

`SyncRates` therefore checks the configured base currency against
`General Ledger Setup."LCY Code"` before writing anything, and refuses
to proceed if they don't match — syncing against a non-LCY base would
silently write incorrect financial master data, a materially worse
failure mode than the sync simply not running. This check is
deliberately skipped (and documented as such) when `"LCY Code"` is
blank, which is common in demo/test companies — the guard can only
catch what it has a real value to compare against.

## A Real Platform Restriction: No Writes Inside a TryFunction

An early version of the per-currency update logic wrapped both the
existence check (`Currency.Get`) and the actual write
(`CurrencyExchangeRate.Insert`/`Modify`) inside a single `[TryFunction]`,
intending to gracefully skip any currency not set up in Business
Central. This failed to compile with: *"Call to the function 'INSERT'
is not allowed inside the call to '...' when it is used as a
TryFunction."*

This is a genuine, long-standing platform rule (since NAV 2017, per
Microsoft's own documentation): a try function's database writes are
**not rolled back** if the function subsequently fails, so the
platform blocks writes inside one outright, to prevent silent,
uncommitted-in-spirit data changes surviving a caught error. The
actual fix was simpler than the original design: `Record.Get()`,
called in its function form, already returns `Boolean` without
throwing — there was never a genuine need for `TryFunction` here at
all. The lesson generalizes: reach for `TryFunction` only for
genuinely unpredictable failures, not for conditions a plain boolean
check already covers.

## Retry Design: No Blocking Delay

`SyncRates` retries a failed provider call up to three times, with
**no artificial delay** between attempts. This is a deliberate choice,
not an oversight: AL's `Sleep()` blocks the entire session for its
duration, which is acceptable in a disposable script but poor practice
in anything resembling production code. A real production system
would implement retry-with-backoff via Business Central's **Job
Queue** — re-enqueuing a delayed follow-up run — rather than freezing
a session synchronously. This project's immediate-retry loop is
appropriately scoped for a portfolio demonstration; the Job Queue
approach is the documented, correct extension point for production
use.

## Partial Success and Test-Data Honesty

A sync can legitimately succeed for some currencies and fail for
others (e.g., a currency the provider returns but that isn't set up in
Business Central's own `Currency` table), reported as `Partial
Success` rather than a flat pass/fail.

The test covering this originally assumed a specific currency (JPY)
would be absent from the test company's `Currency` table — an
assumption that didn't hold in this container's actual CRONUS data,
causing the test to fail for a reason unrelated to the logic under
test. The fix was to stop guessing: the test now probes the real
`Currency` table at run time (`FindNonexistentCurrencyCode`) to find a
genuinely absent code, rather than assuming any particular real
currency's presence or absence in an unknown container's demo data.

## Outbound API: Built, Compiled, Partially Unverified

`FXI Integration Log API` exposes the integration log as a read-only
OData v4 endpoint (`GET .../integrationLogEntries`), with distinct
internal (AL field name) and external (camelCase JSON property name)
naming, matching standard REST/OData API conventions rather than
exposing internal naming verbatim.

**Honest limitation:** live external verification of this endpoint —
calling it with real Basic Authentication from outside the AL/Web
Client environment — was attempted but not completed. Every attempt
(via a browser, and via PowerShell `Invoke-RestMethod` with a manually
constructed Basic Auth header using a generated Web Service Access
Key) was rejected with `Authentication_InvalidCredentials`. This was
narrowed down methodically, not abandoned on first failure:

- Confirmed the *endpoint itself* was reachable and live (ruled out
  wrong port — `ODataServicesPort` is `7048`, confirmed via
  `Get-BCContainerServerConfiguration`; ruled out wrong protocol — the
  container serves OData over plain HTTP,
  `ODataServicesSSLEnabled: false`, not HTTPS).
- Confirmed the *rejection was not specific to this custom page* — an
  identical `Authentication_InvalidCredentials` response was returned
  by Microsoft's own built-in, unmodified `/api/v2.0/companies`
  endpoint, using the exact same credential header. This isolates the
  problem to the container's authentication configuration (likely a
  User Name/Web Service Access Key mismatch, or a credential-type
  nuance specific to this container's setup) and rules out any defect
  in this extension's own code.

The API page's structure, naming conventions, and read-only
enforcement are complete and match Business Central's standard API
page conventions; live, externally-authenticated verification remains
an open item, documented here rather than silently omitted or falsely
claimed as done.

## Testing Philosophy: Offline by Default, Live by Exception

The core automated suite never touches the real network — every test
exercises the mock provider, deterministic and instant. Exactly one
test, `FXI Frankfurter Live Test`, calls the genuine Frankfurter API
and is explicitly marked as a manual/optional check: it asserts shape
and plausibility (rates are present and positive) rather than exact
values, since real market rates change daily and an exact-value
assertion would fail tomorrow through no fault of the code.

## Permissions

A single permission set, `FXI Integration User` — unlike the other two
projects in this portfolio, there is no user/manager distinction here,
since nothing in this project has a "resolve" or "approve" concept for
one role to hold over another. The audit log (`FXI Integration Log`)
is granted read-only with no insert/modify/delete at any tier, since
it is written exclusively by the sync orchestration codeunit.
