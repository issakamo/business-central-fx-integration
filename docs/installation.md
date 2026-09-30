# Installation & Local Development Setup

## Prerequisites

- **Docker Desktop**
- **Visual Studio Code** with the **AL Language** extension
- A Business Central Docker sandbox container
- **Outbound internet access from the container** — confirmed in this
  project's own development via a container-side PowerShell call
  (`Invoke-ScriptInBcContainer`); if your container was built with
  network isolation, the live connector will not be able to reach
  Frankfurter

## 1. Clone the repository

```bash
git clone https://github.com/issakamo/business-central-fx-integration.git
cd business-central-fx-integration
```

## 2. Configure local launch settings

```bash
cp launch.json.example .vscode/launch.json
```

Edit `.vscode/launch.json` with your container's connection details.

## 3. Download symbols and publish

`Ctrl+Shift+P` → **AL: Download Symbols**, then **AL: Publish**.

## 4. Allow outbound HTTP calls for this extension

This is a required, one-time, per-extension step — **without it, the
live Frankfurter connector will fail silently** (`GetRates` returns
`false` with no error detail):

1. In the Web Client, search **"Extension Management."**
2. Find this extension and open **Configure**.
3. On **Extension Settings**, enable **"Allow HttpClient Requests."**

## 5. Configure the integration

1. Search **"FX Integration Setup."**
2. Confirm **Base Currency Code** defaults correctly to your company's
   LCY (it should auto-populate on first open).
3. Choose **Provider**: `Mock` for a safe, offline first test; switch
   to `Frankfurter` once you've confirmed Step 4 is done.
4. Add one or more rows to the **Target Currencies** list (e.g., `EUR`,
   `GBP`).
5. Click **Sync Now**.

## 6. Run automated tests

CodeLens **Run Test** above any codeunit in `test/Codeunits/`, or the
Web Client's **Test Tool**. Note: `FXI Frankfurter Live Test` calls the
real internet and is meant to be run manually/individually, not as
part of routine automated verification.

## Troubleshooting

- **Live connector call silently fails (`GetRates` returns `false`,
  no error)** — almost always Step 4 (outbound HTTP not yet allowed
  for this extension). Confirm there too before suspecting anything
  else.
- **A sync fails with an error about LCY** — the configured Base
  Currency Code doesn't match `General Ledger Setup."LCY Code"`. This
  is deliberate: syncing against the wrong base would write incorrect
  exchange rate data. Correct the Setup page's Base Currency Code to
  match your company's actual LCY.
- **Calling the outbound API (`FXI Integration Log API`) from outside
  Business Central returns `Authentication_InvalidCredentials`** — this
  was a known, unresolved issue at the time this project was last
  verified (see `docs/architecture.md`). Confirm first whether
  Microsoft's own built-in `/api/v2.0/companies` endpoint is
  reachable with your credentials under the same conditions — if it
  also fails, the issue is in the container's authentication
  configuration, not this extension.
  