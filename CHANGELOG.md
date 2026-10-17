# Changelog

## Unreleased

### Proposed manifest `0.1.2`

- `run_agy.sh` accepts an optional `--model <id>` and passes it through as
  `agy --model <id>` (ids: `agy models`). Without it agy's own default model
  applies; the wrapper never picks one. A missing or flag-shaped value exits 2
  before agy runs, unknown flags still exit 2, and the status, verify-failure
  and auth/quota lines report `model=<id|default>`; exit 4 with `--model`
  adds a hint to retry without it before re-authenticating.
- Shell suite grows to 33 synthetic cases (T22-T27b cover forwarding, absence,
  missing value, flag-shaped value, mixing with the verify flags, and the
  exit-4 retry hint).

### Proposed manifest `0.1.1`

Proposed Claude plugin manifest `0.1.1`; stable remains `0.1.0`. No tag,
release, installation, or marketplace publication is part of this patch.

- Keep the 10 MiB transcript cap while draining excess output, so verbose
  delegates can finish result writes and preserve their true exit status.
- Recognize current documented `authentication required` failures without
  reclassifying successful output; make auth hints storage-version-neutral.
- Add a capability-minimal Google-native root plugin marker alongside the
  existing Claude manifest, with offline schema/discovery checks.
- Distinguish July probe evidence from current JSON/auth/plugin documentation;
  retain mechanical-only scope, result-file verification, and legacy flags.
- Expand synthetic shell regression coverage to 21 cases.
