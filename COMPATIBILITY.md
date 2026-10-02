# Package and runtime compatibility

Checked 2026-10-02. Baseline source `a9c60d4`, Claude manifest `0.1.0`;
proposed unreleased Claude manifest `0.1.1`. The Google-native root marker is
capability-minimal and has no version field under the documented Google schema.

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

The shell suite has 21 synthetic cases. Exit 4 remains heuristic and only
refines an already-failed run. Classification inspects the capped transcript,
so a signature appearing only after the cap may be missed; the underlying
failure status remains a failure. Native exit-code collisions are still
identified by the wrapper's diagnostic text, not the number alone.

## Primary sources

- [Google Plugins, including full manifest schema](https://antigravity.google/docs/plugins/):
  root marker, allowed metadata, and `skills/` discovery
- [Google headless CLI](https://antigravity.google/docs/cli/headless/):
  current output/auth/permission semantics
- [Google execution modes](https://antigravity.google/docs/cli/modes/):
  explicit accept-edits mode versus tool permission rules
- [Google installation/auth](https://antigravity.google/docs/cli/install):
  supported version-dependent sign-in
- [Claude manifest reference](https://code.claude.com/docs/en/plugins-reference):
  separate Claude package and version pinning

The standalone Google schema URL was inaccessible through the audit's web
reader; tests implement the schema printed in Google's official Plugins page.
No installer, login, local cache, marketplace setting, or release was changed.
