---
name: antigravity-delegate
description: "EXPERIMENTAL delegate lane for Google Antigravity CLI (agy) - bounded, non-honesty-critical mechanical subtasks via a brief file, as an alternative cheap executor alongside codex-delegate and claude-cheap. Use ONLY when the user explicitly asks to route work to Antigravity/agy, or when validating the lane itself; it is NOT a default routing target until multi-trial reliability lands (current evidence: one n=1 scoped-edit probe, mc11). Not for reviews, completion verdicts, governance, or anything ambiguous - those stay per core routing rules."
---

# antigravity-delegate (EXPERIMENTAL — not a default lane)

Delegates a bounded mechanical subtask to Google Antigravity CLI
(`agy`, installed 1.0.10+). Status is honest and load-bearing:

- **Evidence: n=1.** One scoped-edit + no-commit compliance probe passed
  2026-07-10 (target edited, decoy untouched, zero git ops, exact-format
  reply) — recorded as `mc11_antigravity_scoped_edit_no_commit` in
  `fable-method-harness/benchmarks/model_compatibility_cases.yaml`.
  Capability existence, NOT reliability. Until a multi-trial pass exists,
  the splitter must not emit this lane by default (its reroute table says
  exactly that).
- **Replaces nothing yet.** The dead gemini lane's use-cases were rerouted
  to `claude` / `codex` / `claude-cheap` (splitter 0.3.0). This lane is an
  EXPERIMENTAL alternative cheap executor to trial alongside them.

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

## Before this becomes a real lane (the promotion gate)

Run a pre-registered multi-trial reliability pass (k >= 5 on a fixture
with a planted decoy + a planted judgment question that must be
escalated), record it next to mc11, and only then loosen the splitter's
"not a default lane" row. Until then, invoking this skill for real work
requires the user's explicit ask, and the session notes the lane's
experimental status in its report.

## See also

- `mc11` (evidence + probe artifacts: operator
  `audits/harness-optimization-2026-07/agy-probe-20260710/`)
- `agent-task-splitter` 0.3.0 reroute table (why gemini's use-cases did
  NOT move here)
- `codex-delegate` (the contract this skill's brief shape ports from)
- `fable-method-harness/core/model_routing_playbook.md` (tier guardrails)
