# Changelog

## Unreleased

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
