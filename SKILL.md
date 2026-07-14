---
name: antigravity-delegate
description: "Delegate lane for Google Antigravity CLI (agy) - bounded, non-honesty-critical mechanical subtasks via a brief file, an alternative cheap executor alongside codex-delegate and claude-cheap. Promoted to orchestrator-routed 2026-07-11 after the pre-registered k=5 reliability gate passed 5/5 (mc12; scoped edit + decoy + escalation fixture). Standard cheap-tier guardrails unchanged: never reviews, completion verdicts, governance, or anything ambiguous - those stay per core routing rules."
---

# antigravity-delegate (promoted cheap lane — k=5 gate passed)

Delegates a bounded mechanical subtask to Google Antigravity CLI
(`agy`, installed 1.0.10+). Status is honest and load-bearing:

- **Evidence: n=1 capability + k=5 reliability.** Scoped-edit + no-commit
  compliance probe passed 2026-07-10 (`mc11`); the pre-registered k=5
  reliability gate passed **5/5** on 2026-07-11 (fresh sandbox per trial,
  planted decoy untouched, planted judgment question escalated verbatim
  and not acted on, zero git ops every trial) — recorded as
  `mc12_antigravity_k5_reliability` in
  `fable-method-harness/benchmarks/model_compatibility_cases.yaml`.
  Orchestrators may route bounded mechanical work here without an
  explicit user ask, same as codex-delegate / claude-cheap.
- **Scope honesty.** k=5 covered ONE fixture shape (scoped edit + decoy +
  escalation). New task shapes (multi-file transforms, large briefs)
  deserve their own n=1 probe before heavy routing.
- **Replaces nothing.** The dead gemini lane's use-cases were rerouted
  to `claude` / `codex` / `claude-cheap` (splitter 0.3.0). This lane is an
  alternative cheap executor alongside them.

## Invocation contract (discovered empirically, mc11)

Four non-obvious facts, all mandatory:

1. `--print` mode is **plan-only by default and exits 0 SILENTLY without
   editing**. You MUST pass `--mode accept-edits` for the agent to touch
   files.
2. `--dangerously-skip-permissions` is required ALONGSIDE
   `--mode accept-edits`: the default tool permission is
   `request-review`, which a non-interactive `--print` run cannot answer
   (mc11 raw log) — only ever combine it with a narrowly-granted sandbox
   workspace.
3. The workspace must be granted with an **absolute path** via
   `--add-dir`.
4. Auth lives at `~/.antigravity_cockpit/credentials.json`; when it is
   missing/expired agy hangs or errors — re-auth by running `agy`
   interactively once (browser flow). Never attempt to paste OAuth codes
   non-interactively.

Canonical invocation (or use `scripts/run_agy.sh`, which wraps all of it):

```bash
timeout 300 agy --print \
  "Read .ai/agy_task_<NNN>_<slug>.md in this workspace and execute it
   verbatim; write the result summary to the path it names." \
  --add-dir "<ABSOLUTE workspace path>" \
  --mode accept-edits --dangerously-skip-permissions \
  --print-timeout 240s \
  --log-file .ai/agy_log_<NNN>_<slug>.txt
```

## Hard rules (same spine as codex-delegate; never optional)

- **Only bounded mechanical work**: transcribe, reformat, apply-a-stated-
  pattern, scoped single-purpose edits with a runnable acceptance check.
- **Never** honesty-critical output (reviews, "all green" verdicts,
  spec-discrepancy calls, completion claims), governance/security
  surfaces, or ambiguous specs — cheap-tier guardrails per
  `fable-method-harness/core/model_routing_playbook.md` apply verbatim.
- **Classification stays with the orchestrator** — this lane never
  reclassifies or extends its own scope; uncertainty escalates instead.
- **Brief-first**: write `.ai/agy_task_<NNN>_<slug>.md` (same shape as
  codex briefs — scope-confirmation block first, files in/out of scope,
  acceptance checks, result path `.ai/agy_result_<NNN>_<slug>.md`).
- **No structured-output flag exists** in agy — the result-summary md IS
  the machine-readable contract; the brief must cap it at <=250 words.
- **agy never commits**; the orchestrator reviews the diff, runs the
  acceptance checks itself, and owns staging/commit ("delegate returned"
  is a mandatory review trigger).
- Every run in a sandbox or scoped workspace — grant `--add-dir` to the
  narrowest directory that contains the task.

## Promotion gate — MET 2026-07-11

The pre-registered multi-trial reliability pass (k >= 5, planted decoy +
planted judgment question that must be escalated) ran 2026-07-11: **5/5
PASS**, deterministic grader, criteria frozen before any run. Evidence:
`mc12_antigravity_k5_reliability` (fable-method-harness) + operator
`audits/harness-optimization-2026-07/agy-k5-20260711/` (pre-registration,
results.json, RESULTS.md). The lane is therefore orchestrator-routed;
the hard rules above are unchanged and permanent.

## See also

- `mc11` / `mc12` (evidence + probe artifacts: operator
  `audits/harness-optimization-2026-07/agy-probe-20260710/` and
  `agy-k5-20260711/`)
- `agent-task-splitter` 0.3.1 reroute table (why gemini's use-cases did
  NOT move here; 0.3.1 is the release whose antigravity row records this
  lane's promotion)
- `codex-delegate` (the contract this skill's brief shape ports from)
- `fable-method-harness/core/model_routing_playbook.md` (tier guardrails)
