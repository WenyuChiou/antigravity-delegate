#!/bin/sh
# run_agy.sh — wrapper for the EXPERIMENTAL antigravity-delegate lane.
# Ports run_codex.sh's discipline to agy: brief-on-disk, absolute
# workspace grant, accept-edits + skip-permissions (print mode is
# plan-only+silent without accept-edits, and the default request-review
# tool permission cannot be answered non-interactively — mc11), capped
# log, bounded timeout, TRUE exit-code propagation.
#
# Usage: run_agy.sh <absolute-brief-path> <absolute-workspace-dir> [timeout-sec>30]
# Exit: agy's (or timeout's, e.g. 124) exit code; 2 on usage error.
set -u

BRIEF="${1:-}"; WS="${2:-}"; SECS="${3:-300}"
if [ -z "$BRIEF" ] || [ -z "$WS" ]; then
  echo "usage: run_agy.sh <absolute-brief-path> <absolute-workspace-dir> [timeout-sec>30]" >&2
  exit 2
fi
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

LOG="${BRIEF%.md}_log.txt"
PRINT_TIMEOUT="$((SECS - 30))s"

# POSIX-safe true-exit-code capture: $? after a pipeline is the LAST
# command's (head's, ~always 0) — route agy's real status through a
# temp file instead (the run_codex.sh port initially regressed this).
STATUS_FILE="${LOG}.status.$$"
{
  timeout "$SECS" agy --print \
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
echo "run_agy: exit=$RC log=$LOG (review the diff + run acceptance checks yourself before staging)"
exit "$RC"
