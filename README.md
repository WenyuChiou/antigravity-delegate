# antigravity-delegate

Claude Code skill: delegate bounded, non-honesty-critical mechanical
subtasks to Google Antigravity CLI (`agy`) via a brief file —
an alternative cheap executor alongside
[`codex-delegate`](https://github.com/WenyuChiou/codex-delegate) and
pinned-model Claude lanes.

## Status — read this first

- **Promotion gate passed 2026-07-11**: pre-registered k=5 reliability
  probe, **5/5 PASS** (fresh sandbox per trial; planted decoy untouched;
  planted judgment question escalated verbatim, not acted on; zero git
  ops; deterministic grader, criteria frozen before any run). Recorded
  as `mc12` in
  [fable-method-harness](https://github.com/WenyuChiou/fable-method-harness)
  `benchmarks/model_compatibility_cases.yaml`, alongside the original
  n=1 capability probe (`mc11`, 2026-07-10).
- **Orchestrator-routed** for bounded mechanical work, same as
  codex-delegate / cheap-Claude. Scope honesty: k=5 covered one fixture
  shape (scoped edit + decoy + escalation) — probe new task shapes with
  an n=1 before heavy routing. Cheap-tier guardrails are permanent:
  never reviews / completion verdicts / governance / ambiguous specs.
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
