# antigravity-delegate

**EXPERIMENTAL** Claude Code skill: delegate bounded, non-honesty-critical
mechanical subtasks to Google Antigravity CLI (`agy`) via a brief file —
an alternative cheap executor alongside
[`codex-delegate`](https://github.com/WenyuChiou/codex-delegate) and
pinned-model Claude lanes.

## Status — read this first

- Evidence today is **one n=1 scoped-edit + no-commit probe** (PASS,
  2026-07-10; recorded as `mc11` in
  [fable-method-harness](https://github.com/WenyuChiou/fable-method-harness)
  `benchmarks/model_compatibility_cases.yaml`). Capability existence,
  **not** reliability.
- **Not a default routing lane.** Route here only when the user
  explicitly asks, or when validating the lane itself. The promotion
  gate (pre-registered k≥5 with a planted decoy + a planted judgment
  question that must be escalated) is defined in `SKILL.md`.
- It does **not** replace the retired gemini lane — those use-cases were
  rerouted to claude / codex / cheap-Claude (see
  [agent-collab-skills](https://github.com/WenyuChiou/agent-collab-skills)
  splitter 0.3.0).

## The four invocation facts (all mandatory, discovered empirically)

1. `--print` is plan-only by default and exits 0 **silently** without
   editing → you must pass `--mode accept-edits`.
2. `--dangerously-skip-permissions` is required alongside it — the
   default `request-review` tool permission cannot be answered
   non-interactively. Only combine with a narrowly-granted sandbox.
3. The workspace must be granted with an **absolute** `--add-dir` path.
4. Auth lives at `~/.antigravity_cockpit/credentials.json`; re-auth by
   running `agy` interactively once.

`scripts/run_agy.sh` wraps all of it (bounded timeout, 10 MB log cap,
true exit-code propagation).

## License

MIT.
