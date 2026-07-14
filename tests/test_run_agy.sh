#!/bin/sh
# Regression suite for scripts/run_agy.sh — hardening round 2026-07-14.
# Runs against the ACTUAL deployed shell (git-bash/MSYS on this machine).
# Uses a stub agy binary (AGY_BIN override) so no real quota is spent.
#
# Falsifiability note (rule: every new test must fail pre-fix): the
# pre-hardening wrapper (e48a6bc..4bf63b7) had no flag parsing — with a
# timeout positional present, `--verify-file ...` args were SILENTLY
# IGNORED (verified 2026-07-14: old script ran agy and returned agy's
# code, never 3); without one, the flag landed in $3 and failed the
# integer check (exit 2). Exit codes 3/4 did not exist. T5-T13 therefore
# FAIL on the pre-fix script by construction, either way.
#
# Run:  sh tests/test_run_agy.sh
# Exit code = number of failures (0 = all pass).
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$HERE/../scripts/run_agy.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

WS="$TMP/ws"; mkdir -p "$WS"
BRIEF="$TMP/agy_task.md"; printf '# task\n' > "$BRIEF"

# --- stub agy: behavior driven by STUB_MODE env -----------------------
STUB="$TMP/agy_stub"
cat > "$STUB" <<'EOF'
#!/bin/sh
case "${STUB_MODE:-ok}" in
  ok)          echo "DONE"; exit 0 ;;
  ok_write)    echo "DONE"; printf 'result body SENTINEL-OK\n' > "$STUB_OUT"; exit 0 ;;
  ok_empty)    echo "DONE"; : > "$STUB_OUT"; exit 0 ;;
  ok_nosent)   echo "DONE"; printf 'result body no marker\n' > "$STUB_OUT"; exit 0 ;;
  ok_quota_in_log) echo "task mentions quota exceeded on purpose"; printf 'result SENTINEL-OK\n' > "$STUB_OUT"; exit 0 ;;
  auth_fail)   echo "Error: IneligibleTierError - credential rejected" >&2; exit 1 ;;
  generic_fail) echo "Error: something unrelated broke" >&2; exit 1 ;;
esac
EOF
chmod +x "$STUB"
export AGY_BIN="$STUB"

FAILS=0
t() { # t <name> <expected-exit> <actual-exit>
  if [ "$2" -eq "$3" ]; then echo "PASS $1 (exit $3)"
  else echo "FAIL $1 — expected exit $2, got $3"; FAILS=$((FAILS+1)); fi
}

OUT="$TMP/out.md"
export STUB_OUT="$OUT"

# T1 usage: no args
sh "$WRAPPER" >/dev/null 2>&1; t T1_no_args 2 $?
# T2 relative brief path
sh "$WRAPPER" rel.md "$WS" >/dev/null 2>&1; t T2_relative_brief 2 $?
# T3 bad timeout
sh "$WRAPPER" "$BRIEF" "$WS" 10 >/dev/null 2>&1; t T3_bad_timeout 2 $?
# T4 missing binary
AGY_BIN="$TMP/definitely-not-a-binary" sh "$WRAPPER" "$BRIEF" "$WS" >/dev/null 2>&1; t T4_missing_agy 2 $?
# T5 verify-file written + sentinel present -> 0
rm -f "$OUT"; STUB_MODE=ok_write sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "$OUT" --verify-sentinel "SENTINEL-OK" >/dev/null 2>&1; t T5_verify_pass 0 $?
# T6 verify-file never created -> 3
rm -f "$OUT"; STUB_MODE=ok sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "$OUT" >/dev/null 2>&1; t T6_verify_missing 3 $?
# T7 verify-file empty -> 3
rm -f "$OUT"; STUB_MODE=ok_empty sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "$OUT" >/dev/null 2>&1; t T7_verify_empty 3 $?
# T8 sentinel absent -> 3
rm -f "$OUT"; STUB_MODE=ok_nosent sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "$OUT" --verify-sentinel "SENTINEL-OK" >/dev/null 2>&1; t T8_sentinel_absent 3 $?
# T9 auth signature on nonzero exit -> 4
STUB_MODE=auth_fail sh "$WRAPPER" "$BRIEF" "$WS" 60 >/dev/null 2>&1; t T9_auth_classified 4 $?
# T10 generic nonzero exit passes through -> 1
STUB_MODE=generic_fail sh "$WRAPPER" "$BRIEF" "$WS" 60 >/dev/null 2>&1; t T10_generic_passthrough 1 $?
# T11 fail-safe: 'quota' in a SUCCESSFUL run's log is never reclassified -> 0
rm -f "$OUT"; STUB_MODE=ok_quota_in_log sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "$OUT" >/dev/null 2>&1; t T11_success_never_reclassified 0 $?
# T12 backward compat: plain positional call, no flags -> 0
STUB_MODE=ok sh "$WRAPPER" "$BRIEF" "$WS" 60 >/dev/null 2>&1; t T12_backward_compat 0 $?
# T13 unknown flag -> 2
STUB_MODE=ok sh "$WRAPPER" "$BRIEF" "$WS" 60 --frobnicate x >/dev/null 2>&1; t T13_unknown_flag 2 $?
# T14 glob-decoy: a glob-SHAPED verify path must be treated literally.
# Pre-set-f, "agy_result_*.md" expanded against cwd decoys and the guard
# could fabricate a PASS (reviewer-caught). Decoy contains the sentinel;
# the literal filename never exists -> must be exit 3, not 0.
GLOBDIR="$TMP/globdir"; mkdir -p "$GLOBDIR"
printf 'decoy SENTINEL-OK\n' > "$GLOBDIR/agy_result_001.md"
( cd "$GLOBDIR" && STUB_MODE=ok sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "agy_result_*.md" --verify-sentinel "SENTINEL-OK" ) >/dev/null 2>&1
t T14_glob_treated_literally 3 $?
# T15 flags WITHOUT the timeout positional -> 0
rm -f "$OUT"; STUB_MODE=ok_write sh "$WRAPPER" "$BRIEF" "$WS" --verify-file "$OUT" --verify-sentinel "SENTINEL-OK" >/dev/null 2>&1; t T15_flags_no_timeout 0 $?
# T16 two verify files, second missing -> 3
rm -f "$OUT" "$TMP/second.md"; STUB_MODE=ok_write sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "$OUT" --verify-file "$TMP/second.md" >/dev/null 2>&1; t T16_second_file_missing 3 $?
# T17 verify path containing a space -> 0
SPACED="$TMP/out with space.md"
rm -f "$SPACED"; STUB_OUT="$SPACED" STUB_MODE=ok_write sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "$SPACED" --verify-sentinel "SENTINEL-OK" >/dev/null 2>&1; t T17_spaced_path 0 $?

echo "failures: $FAILS"
exit "$FAILS"
