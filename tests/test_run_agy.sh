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
WRAPPER="${WRAPPER_UNDER_TEST:-$HERE/../scripts/run_agy.sh}"
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
  oversized_write)
    set -e
    dd if=/dev/zero bs=1024 count=12288 2>/dev/null
    printf 'result SENTINEL-OK\n' > "$STUB_OUT"
    exit 0 ;;
  oversized_fail)
    set -e
    dd if=/dev/zero bs=1024 count=12288 2>/dev/null
    exit 7 ;;
  auth_required) echo "Error: authentication required" >&2; exit 1 ;;
  record_args) printf '%s\n' "$@" > "$STUB_ARGS"; echo "DONE"; exit 0 ;;
  record_write) printf '%s\n' "$@" > "$STUB_ARGS"; printf 'result body SENTINEL-OK\n' > "$STUB_OUT"; echo "DONE"; exit 0 ;;
  effort_fail) printf '%s\n' "$@" > "$STUB_ARGS"; echo "model does not support requested reasoning effort" >&2; exit 7 ;;
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

# T18-20: capping the transcript must not close the producer pipe early.
# A delegate may still need to write its result or return its real exit code
# after logging >10 MiB. The previous `head`-only pipeline sends SIGPIPE.
rm -f "$OUT"
STUB_MODE=oversized_write sh "$WRAPPER" "$BRIEF" "$WS" 60 --verify-file "$OUT" --verify-sentinel "SENTINEL-OK" >/dev/null 2>&1
t T18_oversized_success_finishes 0 $?
LOG="${BRIEF%.md}_log.txt"
t T19_log_stays_capped 10485760 "$(wc -c < "$LOG")"
STUB_MODE=oversized_fail sh "$WRAPPER" "$BRIEF" "$WS" 60 >/dev/null 2>&1
t T20_oversized_failure_preserved 7 $?

# T21: current official headless docs use this unauthenticated error.
STUB_MODE=auth_required sh "$WRAPPER" "$BRIEF" "$WS" 60 >/dev/null 2>&1
t T21_current_auth_required_classified 4 $?

# T22-T27b: --model pass-through. The stub records one argv entry per line.
ARGS="$TMP/agy_args.txt"
export STUB_ARGS="$ARGS"
# model_after_flag: print the argv entry right after --model (empty if none).
model_after_flag() { awk 'prev == "--model" { print; exit } { prev = $0 }' "$ARGS"; }
# T22 --model forwarded verbatim as `--model <id>` -> 0
rm -f "$ARGS"; STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --model gemini-3.8-flash-low >/dev/null 2>&1
t T22_model_forwarded 0 $?
[ "$(model_after_flag)" = "gemini-3.8-flash-low" ]; t T22b_model_value_verbatim 0 $?
# T23 no --model -> agy gets no --model, so its own default applies
rm -f "$ARGS"; STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 >/dev/null 2>&1
t T23_no_model_runs 0 $?
grep -qx -- '--model' "$ARGS"; t T23b_no_model_flag_passed 1 $?
# T24 --model with no value -> 2, agy never runs
rm -f "$ARGS"; STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --model >/dev/null 2>&1
t T24_model_missing_value 2 $?
[ ! -e "$ARGS" ]; t T24b_agy_not_run 0 $?
# T25 flag-shaped value is refused, not swallowed -> 2. It is the LAST
# argument, so without the guard agy would run with model "--verify-sentinel".
rm -f "$ARGS"; STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --model --verify-sentinel >/dev/null 2>&1
t T25_model_flag_shaped_value 2 $?
[ ! -e "$ARGS" ]; t T25b_agy_not_run 0 $?
# T26 --model mixed with verify flags, no timeout positional -> 0, still forwarded
rm -f "$OUT" "$ARGS"; STUB_MODE=record_write sh "$WRAPPER" "$BRIEF" "$WS" --verify-file "$OUT" --model claude-sonnet-5-5-low --verify-sentinel "SENTINEL-OK" >/dev/null 2>&1
t T26_model_with_verify_flags 0 $?
[ "$(model_after_flag)" = "claude-sonnet-5-5-low" ]; t T26b_model_forwarded_with_verify 0 $?
# T27 auth/quota failure with --model -> 4, plus the retry-without-model hint
STUB_MODE=auth_fail sh "$WRAPPER" "$BRIEF" "$WS" 60 --model some-id >/dev/null 2>"$TMP/err.txt"
t T27_auth_with_model 4 $?
grep -q 'retry without --model' "$TMP/err.txt"; t T27b_model_retry_hint 0 $?

# Effort feature-positive cases fail before --effort exists. Bad-argument and
# absent-flag cases also preserve fail-closed/default behavior; those are
# preservation checks rather than claims that every new case failed pre-fix.
effort_after_flag() { if [ -f "$ARGS" ]; then awk 'prev == "--effort" { print; exit } { prev = $0 }' "$ARGS"; fi; }
flag_count() { if [ -f "$ARGS" ]; then grep -cx -- "$1" "$ARGS"; else printf '0\n'; fi; }
rm -f "$ARGS"
STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --effort medium >"$TMP/effort-status.txt" 2>&1
t T28_effort_alone 0 $?
[ "$(effort_after_flag)" = medium ]; t T28b_effort_value 0 $?
t T28c_effort_does_not_add_model 0 "$(flag_count --model)"
grep -q 'effort=medium' "$TMP/effort-status.txt"; t T28d_requested_effort_label 0 $?

rm -f "$ARGS"
STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 >/dev/null 2>&1
t T29_default_run 0 $?
t T29b_no_effort_override 0 "$(flag_count --effort)"

rm -f "$OUT" "$ARGS"
STUB_MODE=record_write sh "$WRAPPER" "$BRIEF" "$WS" --verify-file "$OUT" --model gemini-4-argon-high --effort high --verify-sentinel SENTINEL-OK >/dev/null 2>&1
t T30_argon_and_effort_with_verification 0 $?
[ -f "$ARGS" ] && [ "$(model_after_flag)" = gemini-4-argon-high ]; t T30b_argon_model_verbatim 0 $?
[ "$(effort_after_flag)" = high ]; t T30c_effort_with_model 0 $?
t T30d_one_model_pair 1 "$(flag_count --model)"
t T30e_one_effort_pair 1 "$(flag_count --effort)"

rm -f "$ARGS"
STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --effort >/dev/null 2>&1
t T31_effort_missing_value 2 $?
[ ! -e "$ARGS" ]; t T31b_missing_effort_never_runs 0 $?
STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --effort --model gemini-4-argon-high >/dev/null 2>&1
t T32_effort_flag_shaped_value 2 $?
[ ! -e "$ARGS" ]; t T32b_flag_shaped_effort_never_runs 0 $?
STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --effort '' >/dev/null 2>&1
t T33_empty_effort_value 2 $?
[ ! -e "$ARGS" ]; t T33b_empty_effort_never_runs 0 $?

rm -f "$ARGS"
STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --effort low --model gemini-4-argon-low >/dev/null 2>&1
t T34_effort_before_model 0 $?
[ -f "$ARGS" ] && [ "$(model_after_flag)" = gemini-4-argon-low ]; t T34b_reverse_argon_model 0 $?
[ "$(effort_after_flag)" = low ]; t T34c_reverse_effort 0 $?
rm -f "$ARGS"
STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --effort low --effort high >/dev/null 2>&1
t T35_repeated_effort_runs 0 $?
[ "$(effort_after_flag)" = high ]; t T35b_last_effort_wins 0 $?
t T35c_no_duplicate_effort_pairs 1 "$(flag_count --effort)"

rm -f "$ARGS"
STUB_MODE=effort_fail sh "$WRAPPER" "$BRIEF" "$WS" 60 --model gemini-4-argon-high --effort max >/dev/null 2>&1
t T36_native_effort_error_preserved 7 $?
[ "$(effort_after_flag)" = max ]; t T36b_native_validates_model_support 0 $?
STUB_MODE=auth_fail sh "$WRAPPER" "$BRIEF" "$WS" 60 --model gemini-4-argon-high --effort high >/dev/null 2>"$TMP/effort-auth.txt"
t T37_auth_classification_unchanged 4 $?
grep -q 'effort=high' "$TMP/effort-auth.txt"; t T37b_auth_effort_label 0 $?

rm -f "$ARGS"
STUB_MODE=record_args sh "$WRAPPER" "$BRIEF" "$WS" 60 --effort 'high; literal value' >/dev/null 2>&1
t T38_effort_argument_is_data 0 $?
[ "$(effort_after_flag)" = 'high; literal value' ]; t T38b_effort_single_argv_entry 0 $?

echo "failures: $FAILS"
exit "$FAILS"
