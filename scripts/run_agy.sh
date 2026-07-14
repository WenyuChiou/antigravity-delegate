#!/bin/sh
# run_agy.sh — wrapper for the antigravity-delegate lane.
# Ports run_codex.sh's discipline to agy: brief-on-disk, absolute
# workspace grant, accept-edits + skip-permissions (print mode is
# plan-only+silent without accept-edits, and the default request-review
# tool permission cannot be answered non-interactively — mc11), capped
# log, bounded timeout, TRUE exit-code propagation, verify-file guard,
# auth/quota failure classification.
#
# Usage: run_agy.sh <absolute-brief-path> <absolute-workspace-dir> [timeout-sec>30]
#                   [--verify-file <path>]... [--verify-sentinel <string>]
# Exit: agy's (or timeout's, e.g. 124) exit code;
#       2 usage/environment error (bad args, missing brief/workspace/agy);
#       3 verify failed — agy exited 0 but a --verify-file output is
#         missing/empty or lacks the --verify-sentinel (F13 "liar mode":
#         a delegate claiming completion without producing output);
#       4 auth/quota failure — agy exited NONZERO and the log matches
#         known credential/rate-limit signatures (re-auth: run `agy`
#         interactively once; creds at ~/.antigravity_cockpit).
#         Fail-safe direction by design: classification only ever
#         REFINES an already-failed run — an RC=0 run is never
#         reclassified (briefs/task text can legitimately contain words
#         like "quota" or "unauthorized"); the hint is heuristic and can
#         misfire on unrelated failures whose logs mention these words.
# Collision caveat: agy itself may natively exit 2/3/4; the wrapper
# injects 3 only when RC=0 (verify guard) and 4 only on RC!=0 + log
# match — a native agy 3/4 passes through unchanged, so disambiguate by
# the stderr line ('VERIFY FAILED' / 'reclassified as AUTH/QUOTA' vs the
# generic passthrough message), not by the number alone.
set -u

BRIEF="${1:-}"; WS="${2:-}"
if [ -z "$BRIEF" ] || [ -z "$WS" ]; then
  echo "usage: run_agy.sh <absolute-brief-path> <absolute-workspace-dir> [timeout-sec>30] [--verify-file <path>]... [--verify-sentinel <string>]" >&2
  exit 2
fi
shift 2

# Optional third positional (timeout) — only if it is not a flag.
SECS=300
if [ $# -gt 0 ]; then
  case "$1" in
    --*) : ;;
    *) SECS="$1"; shift ;;
  esac
fi

# Optional flags. POSIX sh has no arrays: newline-join the verify paths
# (paths with embedded newlines are not supported — acceptable for .ai/
# result files, which this guard exists to check).
VERIFY_FILES=""
VERIFY_SENTINEL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --verify-file)
      [ -n "${2:-}" ] || { echo "--verify-file needs a path" >&2; exit 2; }
      VERIFY_FILES="${VERIFY_FILES}${2}
"
      shift 2 ;;
    --verify-sentinel)
      [ -n "${2:-}" ] || { echo "--verify-sentinel needs a string" >&2; exit 2; }
      VERIFY_SENTINEL="$2"
      shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "$BRIEF" in
  /*|[A-Za-z]:*) : ;;
  *) echo "brief must be an ABSOLUTE path (agy only sees the granted workspace, not this shell's cwd)" >&2; exit 2 ;;
esac
case "$WS" in
  /*|[A-Za-z]:*) : ;;
  *) echo "workspace must be an ABSOLUTE path (agy --add-dir requirement)" >&2; exit 2 ;;
esac
if [ ! -f "$BRIEF" ]; then echo "brief not found: $BRIEF" >&2; exit 2; fi
if [ ! -d "$WS" ]; then echo "workspace not found: $WS" >&2; exit 2; fi
if ! [ "$SECS" -gt 30 ] 2>/dev/null; then
  echo "timeout-sec must be an integer > 30 (margin needed for --print-timeout)" >&2
  exit 2
fi
# AGY_BIN override exists for the test suite (a stub binary); production
# callers omit it and get the real `agy` from PATH. Test-only escape
# hatch — not meant for environments that accept untrusted env input
# (an attacker controlling env already controls PATH anyway).
AGY_BIN="${AGY_BIN:-agy}"
if ! command -v "$AGY_BIN" >/dev/null 2>&1; then
  echo "run_agy: '$AGY_BIN' not found on PATH — install Antigravity CLI:" >&2
  echo "  curl -fsSL https://antigravity.google/cli/install.sh | bash   (or winget: Google.AntigravityCLI)" >&2
  exit 2
fi

LOG="${BRIEF%.md}_log.txt"
PRINT_TIMEOUT="$((SECS - 30))s"

# POSIX-safe true-exit-code capture: $? after a pipeline is the LAST
# command's (head's, ~always 0) — route agy's real status through a
# temp file instead (the run_codex.sh port initially regressed this).
STATUS_FILE="${LOG}.status.$$"
{
  timeout "$SECS" "$AGY_BIN" --print \
    "Read $BRIEF in this workspace and execute it verbatim. Follow its scope
confirmation, acceptance checks, and result-file instructions exactly.
Do not run any git commands. Reply with the one-line status the brief
requests." \
    --add-dir "$WS" \
    --mode accept-edits \
    --dangerously-skip-permissions \
    --print-timeout "$PRINT_TIMEOUT"
  echo $? > "$STATUS_FILE"
} 2>&1 | head -c 10485760 > "$LOG"
RC=$(cat "$STATUS_FILE" 2>/dev/null || echo 1)
rm -f "$STATUS_FILE"
tail -3 "$LOG"

if [ "$RC" -ne 0 ]; then
  # Classify the failure (advisory refinement of an already-nonzero RC).
  # Misclassification direction annotated: a missed match falls through
  # to the raw RC (safe — orchestrator still sees a failure); a false
  # match turns one failure code into another failure code (never into
  # success), so no green can be fabricated here.
  if grep -qiE 'IneligibleTierError|UNSUPPORTED_CLIENT|invalid_grant|credentials? (rejected|invalid|expired|missing)|unauthorized|quota exceeded|rate.?limit|RESOURCE_EXHAUSTED|too many requests|error 429' "$LOG"; then
    echo "run_agy: exit=$RC reclassified as AUTH/QUOTA failure (exit 4) — likely expired ~/.antigravity_cockpit credentials or a rate limit. Re-auth: run 'agy' interactively once. log=$LOG" >&2
    exit 4
  fi
  if [ "$RC" -eq 124 ] && [ ! -s "$LOG" ]; then
    # Ambiguous on purpose: agy --print buffers output, so ANY timeout
    # tends to leave an empty log — could be a slow task OR the
    # documented auth-expiry hang. Hint, but do NOT reclassify.
    echo "run_agy: timeout with an empty log — either the task outgrew ${SECS}s or agy is hanging on expired auth; check by running 'agy' interactively once." >&2
  fi
  echo "run_agy: exit=$RC log=$LOG (review the diff + run acceptance checks yourself before staging)"
  exit "$RC"
fi

# RC=0: enforce the result contract (F13 guard). SKILL.md puts the
# result file in agent hands; this is the wrapper-side existence check
# that design itself calls for.
if [ -n "$VERIFY_FILES" ]; then
  OLDIFS=$IFS
  IFS='
'
  # set -f: an unquoted for-list undergoes PATHNAME EXPANSION as well as
  # field-splitting — without this, a glob-shaped --verify-file argument
  # (e.g. result_*.md) could silently match decoy files in cwd and let
  # the anti-fabrication guard itself fabricate a PASS (reviewer-caught,
  # 2026-07-14, empirically reproduced).
  set -f
  for VF in $VERIFY_FILES; do
    IFS=$OLDIFS
    if [ ! -s "$VF" ]; then
      echo "run_agy: VERIFY FAILED (exit 3) — agy exited 0 but expected output is missing or empty: $VF" >&2
      exit 3
    fi
    if [ -n "$VERIFY_SENTINEL" ] && ! grep -qF "$VERIFY_SENTINEL" "$VF"; then
      echo "run_agy: VERIFY FAILED (exit 3) — sentinel '$VERIFY_SENTINEL' not found in: $VF" >&2
      exit 3
    fi
    IFS='
'
  done
  set +f
  IFS=$OLDIFS
fi

echo "run_agy: exit=$RC log=$LOG (review the diff + run acceptance checks yourself before staging)"
exit "$RC"
