# Package and runtime compatibility

The initial audit below was checked 2026-10-02 against source `a9c60d4`
and Claude manifest `0.1.0`; `--model` was rechecked 2026-10-17.
The 2026-10-25 update targets Claude plugin `0.1.3` and adds independent
effort forwarding. The Google-native root marker remains capability-minimal
and has no version field under the documented Google schema.

## Three independent surfaces

| Surface | Entry point | Evidence |
|---|---|---|
| Claude marketplace plugin | `.claude-plugin/plugin.json` | Existing manifest and installable-skill byte-parity tests |
| Portable skill directory | `skills/antigravity-delegate/` | Bundled skill/wrapper topology and byte parity |
| Google-native plugin | Root `plugin.json` plus `skills/*/SKILL.md` | Offline required-name, string, name-pattern, allowed-field, and discovery checks |

The Google marker contains only `name` and `description`. It declares no
MCP server, hook, setting, or permission. It does not replace the Claude
manifest. Changing the host does not broaden mechanical-only scope or allow
the delegate to make governance, security, ambiguity, or completion judgments.

`agy`/Antigravity executables and Claude CLI were absent in this Linux audit.
Actual native plugin loading, authentication, installed agy version/flags,
model execution, and the historical July reliability probe were not rerun.

## Historical contract versus current docs

The preserved wrapper comes from the July `1.0.10+` probe. Current Google
headless docs list JSON/schema output and noninteractive auth errors; current
auth docs use keyring sign-in and different settings locations. Those facts
qualify the old no-JSON/fixed-credential-path claims, rather than proving the
legacy invocation on a new runtime. Existing flags and result-file verification
remain unchanged until an installed-version check and scoped live probe exist.

## Synthetic comparable cases

- Before: a 12 MiB stub transcript hit the 10 MiB `head` cap and killed the
  producer before its result/status write; intended success and native exit 7
  both returned 1. After: excess bytes are drained, the result is verified,
  the log remains exactly 10,485,760 bytes, and exit 7 is preserved.
- Before: the current documented `authentication required` failure passed
  through as exit 1. After: it gets the existing advisory AUTH/QUOTA exit 4;
  successful transcripts still never get reclassified.
- Before: the native root marker was missing. After: documented marker/schema
  and skills discovery checks pass offline. This is not a host-loading pass.

Run both suites after the final changes:

```bash
python -m pytest -q
sh tests/test_run_agy.sh
```

The shell suite uses a synthetic backend, including model/effort cases added
on 2026-10-25. Exit 4 remains heuristic and only
refines an already-failed run. Classification inspects the capped transcript,
so a signature appearing only after the cap may be missed; the underlying
failure status remains a failure. Native exit-code collisions are still
identified by the wrapper's diagnostic text, not the number alone.

## 2026-10-17: `--model` pass-through (manifest `0.1.2`)

Installed `agy` 1.4.0 on Windows lists `--model` ("Model for the current CLI
session") in `agy --help`, and `agy models` lists the available ids. The
wrapper forwards `--model <id>` unchanged and adds nothing when the flag is
absent, so agy's own default still applies. The synthetic suite covers the
argument handling; it does not prove that a given id is available to a given
account.

## 2026-10-25: independent `--effort` and Argon selection

Metadata-only checks on Windows with `agy` 1.4.7 show `--model` and
`--effort` in help and list `gemini-4-argon-low`,
`gemini-4-argon-medium`, and `gemini-4-argon-high` in `agy models`.
Google documents low, medium, high, xhigh and max levels, with support
depending on the selected model. The wrapper forwards the requested value;
it does not assert that every model supports every level.

Both flags are optional per-call overrides. Neither sets the other, changes
global settings, retries, or silently substitutes another model. Invalid
missing/empty/flag-shaped arguments fail before invocation; unsupported
model/effort combinations are left to native validation. Diagnostics report
the requested overrides, not observed effective settings.

New feature-positive tests fail against the prior wrapper and pass after
implementation. Synthetic cases cover standalone effort, Argon plus effort
in either order, unchanged defaults, malformed values, verification, native
failure propagation and quoted values. They run against both wrapper copies.
No live generation, account entitlement, authentication, quota, model quality
or cost claim is established, and the July reliability evidence is not renewed.

## Primary sources

- [Google Plugins, including full manifest schema](https://antigravity.google/docs/plugins/):
  root marker, allowed metadata, and `skills/` discovery
- [Google headless CLI](https://antigravity.google/docs/cli/headless/):
  current output/auth/permission semantics
- [Google effort command](https://antigravity.google/docs/cli/commands/effort):
  per-call override versus persistent interactive setting; model-specific support
- [Google execution modes](https://antigravity.google/docs/cli/modes/):
  explicit accept-edits mode versus tool permission rules
- [Google installation/auth](https://antigravity.google/docs/cli/install):
  supported version-dependent sign-in
- [Claude manifest reference](https://code.claude.com/docs/en/plugins-reference):
  separate Claude package and version pinning

The standalone Google schema URL was inaccessible through the audit's web
reader; tests implement the schema printed in Google's official Plugins page.
The 2026-10-02 audit did not change any installer, login, local cache,
marketplace setting or release. That historical observation does not describe
subsequent publication or installation.
