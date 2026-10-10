# Architecture & Design Decisions

This document explains *why* the extension is built the way it is,
including real Business Central platform behaviors uncovered during
development, design flaws found and fixed along the way, and one
honestly documented verification gap.

## Interface-Based Connector Design

`FXI Exchange Rate Provider` is an AL `interface`: a contract
(`GetRates`) with no implementation of its own. Two codeunits implement
it: `FXI Mock Exchange Rate Provider` (fixed, instant, offline data)
and `FXI Frankfurter Rate Provider` (a real `HttpClient` call to
Frankfurter). The orchestration logic (`FXI Exchange Rate Sync
Mgt.SyncRates`) is written against the interface, never against either
implementation by name. Which one runs is decided by the caller: a
test chooses the mock, and the Setup page's `Provider` field chooses
either at runtime. Because the mock writes fixed placeholder rates into
the real Currency Exchange Rate table, selecting it is only allowed in
sandbox environments (`Environment Information.IsSandbox()`), so it
can't overwrite live financial data in production. The check runs both
when the field is set and again when a sync starts.

This addresses, at the design stage, a problem the companion projects
met after the fact: automated tests shouldn't depend on unpredictable
real-world behavior. Here the tests use the mock and never touch the
network.

A codeunit that `implements` an interface incorrectly **fails to
compile**. That is a stronger safety net than event subscribers, where
a wrong signature can fail silently at runtime.

## Why Frankfurter, and What Calling It Revealed

Frankfurter (`api.frankfurter.dev`) was chosen as a free, keyless, real
financial data API. It suits Business Central well, which has a native
`Currency Exchange Rate` table this data feeds directly.

Its actual v2 response shape was verified with a direct browser
request before any parsing code was written, and it differed from what
documentation search results suggested. **The response is a flat JSON
array** of `{date, base, quote, rate}` rows, not a single nested object
(`{"rates": {...}}`) as an older v1-style API might return. Parsing is
therefore `JsonArray`-based.

## Business Central Blocks Outbound HTTP by Default

The first live call to Frankfurter failed silently: `HttpClient.Get`
returned `false` with no further detail. The same happened for an
unrelated control endpoint (`api.github.com`), used specifically to
rule out a Frankfurter-specific cause, while a PowerShell request run
inside the same container succeeded, which ruled out Docker networking.
The cause is a documented Business Central security feature: **outbound
`HttpClient` calls are blocked by default for every extension**, and
must be enabled per extension via Extension Management → Configure →
*Allow HttpClient Requests*. It is a deliberate safeguard against data
exfiltration, and the first thing to check when an extension's
outbound calls fail with no error detail.

## Financial Data Safety: the LCY Guard

Business Central's `Currency Exchange Rate` table stores rates
**relative to the company's local currency (LCY)**: a `Currency Code`
(the foreign currency) with a blank `Relational Currency Code`
(implicitly the LCY). It has no concept of an arbitrary cross-rate
between two foreign currencies.

The base currency is therefore not user-editable. The Setup page takes
it from General Ledger Setup's `LCY Code` every time it opens. An
earlier version stored it as an editable field related to the
`Currency` table, which contradicted the LCY rule twice: Business
Central's LCY normally isn't a row in the `Currency` table (that table
holds foreign currencies), so the one valid value could be rejected;
and a blank value would have let the provider fall back to its own
default base currency.

`SyncRates` also checks, before writing anything:
- A blank base currency is refused outright
  (`SyncRates_BlankBaseCurrency_Fails`).
- A base currency that doesn't match `General Ledger Setup."LCY Code"`
  is refused (`SyncRates_BaseCurrencyNotLCY_Fails`), since syncing
  against a non-LCY base would silently write incorrect master data, a
  worse failure than the sync not running.

## Writing to Currency Exchange Rate

Rates are written with `Validate` rather than direct field assignment,
so Business Central's own field logic runs. Business Central does not
fill in the adjustment amounts (`Adjustment Exch. Rate Amount`,
`Relational Adjmt Exch Rate Amt`) from the exchange rate, and the
Adjust Exchange Rates process uses them, so they are set explicitly
to match it. That is the standard setup, and matches the demo
company's own rates. An earlier version assigned the fields directly,
and a later one assumed `Validate` would fill the adjustment amounts.
Both left them at zero, which a check in the Web Client caught.
Covered by `SyncRates_WritesAdjustmentAmounts`.

Each row's `Starting Date` is the date the rates were retrieved
(`Today`), not the work date. Unlike posting logic, which follows the
work date by Business Central convention, these are real-world rates
tied to the actual day they were published. A second sync on the same
day updates that day's row, and a sync on a later day adds a new one,
so Business Central keeps a history of daily rates. A later refinement
could use the rate date Frankfurter returns with each row.

## A Platform Restriction: No Writes Inside a TryFunction

An early version wrapped both the currency existence check
(`Currency.Get`) and the write (`Insert` / `Modify`) in a single
`[TryFunction]`, intending to skip gracefully any currency not set up
in Business Central. It failed with: *"Call to the function 'INSERT' is
not allowed inside the call to '...' when it is used as a
TryFunction."*

This is a long-standing platform rule: a try function's database
writes are **not rolled back** if it fails, so the platform blocks
writes inside one outright. The fix was simpler than the original
design. `Record.Get()`, called in its function form, already returns
`Boolean` without throwing, so no `TryFunction` was ever needed here.
The lesson: use `TryFunction` only for genuinely unpredictable
failures, not for conditions a plain Boolean check already covers.

## Retry Design: No Blocking Delay

`SyncRates` retries a failed provider call up to three times, with
**no artificial delay** between attempts. AL's `Sleep()` blocks the
whole session for its duration, which is poor practice in production
code. A production system would implement retry with backoff via
Business Central's **Job Queue**, re-enqueuing a delayed follow-up run,
rather than freezing a session. The immediate-retry loop is scoped for
this portfolio; the Job Queue is the documented extension point for
production use.

## Failed Runs Are Logged: Commit Before Error

When the provider call fails after all retries, `SyncRates` writes a
`Failed` entry to the Integration Log and raises a structured
`ErrorInfo` error, with a user-facing `Message` and a `DetailedMessage`
pointing to the specific log entry. Because an AL `Error()` rolls back
the entire transaction, the log entry is committed *before* the error
is raised. Without that commit, the Failed entry would be rolled back
with everything else, and failed runs (the ones an audit log most needs)
would never be recorded. An earlier version had exactly this flaw.

`SyncRates` is only invoked from the Setup page's **Sync Now** action,
so the commit doesn't commit unrelated work from a calling process.
Calling it from inside a larger transaction, or from an automated test
under default isolation (where an explicit `Commit()` fails the test),
would need this revisited. The failure path is therefore verified
manually: turning off *Allow HttpClient Requests* makes the live
provider fail, which produces three attempts, the `ErrorInfo` message,
and a persisted `Failed` log entry.

## Partial Success and Test-Data Honesty

A sync can succeed for some currencies and fail for others, for
example a currency the provider returns but that isn't set up in
Business Central's own `Currency` table. That is reported as
`Partial Success` rather than a flat pass or fail, and the remaining
currencies are still processed.

The test covering this originally assumed a specific currency (JPY)
would be absent from the test company's `Currency` table. That didn't
hold in this container's CRONUS data, so the test failed for a reason
unrelated to the logic under test. The fix was to stop guessing: the
test now probes the real `Currency` table at run time
(`FindNonexistentCurrencyCode`) to find a genuinely absent code. The
mock provider returns a placeholder rate for any currency it doesn't
specifically recognize, so only Business Central-side currency
existence is under test.

## Setup Controls

The Setup page's **Enabled** flag is enforced: Sync Now refuses to run
while the integration is disabled. An earlier version showed the flag
but never checked it.

## Outbound API: Built, Partially Unverified

`FXI Integration Log API` exposes the integration log as a read-only
OData v4 endpoint (`GET .../integrationLogEntries`). Internal AL field
names and external JSON property names are deliberately separate, with
camelCase on the API side, following standard REST and OData
conventions. The page is keyed by `SystemId` (exposed as `id`),
following Microsoft's convention for API pages. Insert, modify, and
delete are disabled, since the log is written only by `SyncRates`.

**Honest limitation:** calling this endpoint from outside Business
Central with real Basic Authentication was attempted but not completed.
Every attempt, from a browser and from PowerShell `Invoke-RestMethod`
with a manually constructed Basic Auth header using a generated Web
Service Access Key, was rejected with `Authentication_InvalidCredentials`.
It was narrowed down methodically:

- The *endpoint itself* is reachable and live. The wrong port was ruled
  out (`ODataServicesPort` is `7048`, confirmed via
  `Get-BCContainerServerConfiguration`), and so was the wrong protocol:
  the container serves OData over plain HTTP
  (`ODataServicesSSLEnabled: false`), not HTTPS.
- The rejection is *not specific to this page*. Microsoft's own built-in
  `/api/v2.0/companies` endpoint returned the identical
  `Authentication_InvalidCredentials` response with the same credential
  header. That isolates the problem to the container's authentication
  configuration, and rules out a defect in this extension's code.

The API page's structure, naming, and read-only enforcement are
complete and follow Business Central's API page conventions. Live,
externally authenticated verification remains an open item, documented
here rather than omitted or claimed as done.

## Testing Philosophy: Offline by Default, Live by Exception

The core automated suite never touches the real network. Every test
uses the mock provider, so results are deterministic and instant.
Exactly one test, `FXI Frankfurter Live Test`, calls the real
Frankfurter API, and is explicitly a manual, optional check. It asserts
shape and plausibility (the requested rates are present and positive)
rather than exact values, since real market rates change daily, and an
exact-value assertion would fail tomorrow through no fault of the code.

## Permissions

There is a single permission set, `FXI Integration User`. Unlike the
other two projects in this portfolio, there is no user/manager split,
since nothing here has a "resolve" or "approve" concept for one role to
hold over another. The integration log is read-only at every level,
because it is written only by the sync orchestration codeunit. Target
currencies are fully editable, since users are meant to add and remove
them. The setup record can be read and modified, but not deleted.