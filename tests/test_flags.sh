#!/usr/bin/env bash
# Test suite for codex-skill — validates all CLI flags and presets
# Usage: ./tests/test_flags.sh
# Requires: codex CLI installed and authenticated

set -euo pipefail

PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1 — $2"; ((FAIL++)); }
skip() { echo "  SKIP: $1 — $2"; ((SKIP++)); }

# Check codex is installed
if ! command -v codex &>/dev/null; then
  echo "ERROR: codex CLI not found. Install with: npm i -g @openai/codex"
  exit 1
fi

echo "Testing codex-cli $(codex --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo 'unknown')"
echo ""

# ─── Preset Tests ───────────────────────────────────────────────────

echo "=== Preset Commands ==="

echo "  Testing turbo preset (low effort)..."
output=$(codex --search exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto --skip-git-repo-check "respond with exactly: TURBO_OK" 2>&1)
if echo "$output" | grep -q "TURBO_OK"; then pass "turbo preset"; else fail "turbo preset" "expected TURBO_OK"; fi

echo "  Testing balanced preset (medium effort)..."
output=$(codex --search exec -m gpt-5.4 -c model_reasoning_effort="medium" --full-auto --skip-git-repo-check "respond with exactly: BALANCED_OK" 2>&1)
if echo "$output" | grep -q "BALANCED_OK"; then pass "balanced preset"; else fail "balanced preset" "expected BALANCED_OK"; fi

echo "  Testing quality preset (high effort)..."
output=$(codex --search exec -m gpt-5.4 -c model_reasoning_effort="high" --full-auto --skip-git-repo-check "respond with exactly: QUALITY_OK" 2>&1)
if echo "$output" | grep -q "QUALITY_OK"; then pass "quality preset"; else fail "quality preset" "expected QUALITY_OK"; fi

echo "  Testing max preset (xhigh effort)..."
output=$(codex --search exec -m gpt-5.4 -c model_reasoning_effort="xhigh" --full-auto --skip-git-repo-check "respond with exactly: MAX_OK" 2>&1)
if echo "$output" | grep -q "MAX_OK"; then pass "max preset"; else fail "max preset" "expected MAX_OK"; fi

# ─── Sandbox Mode Tests ─────────────────────────────────────────────

echo ""
echo "=== Sandbox Modes ==="

echo "  Testing read-only sandbox..."
output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" -s read-only --skip-git-repo-check "respond with exactly: READONLY_OK" 2>&1)
if echo "$output" | grep -q "READONLY_OK"; then pass "read-only sandbox"; else fail "read-only sandbox" "unexpected output"; fi

echo "  Testing workspace-write sandbox..."
output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" -s workspace-write --full-auto --skip-git-repo-check "respond with exactly: WRITE_OK" 2>&1)
if echo "$output" | grep -q "WRITE_OK"; then pass "workspace-write sandbox"; else fail "workspace-write sandbox" "unexpected output"; fi

# ─── Flag Tests ──────────────────────────────────────────────────────

echo ""
echo "=== Individual Flags ==="

# -a (global flag, must come before exec)
echo "  Testing -a global flag..."
output=$(codex -a on-request exec -m gpt-5.4 -c model_reasoning_effort="low" -s read-only --skip-git-repo-check "respond with exactly: APPROVAL_OK" 2>&1)
if echo "$output" | grep -q "APPROVAL_OK"; then pass "-a on-request (global)"; else fail "-a on-request (global)" "unexpected output"; fi

# --ephemeral
echo "  Testing --ephemeral flag..."
output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto --ephemeral --skip-git-repo-check "respond with exactly: EPHEMERAL_OK" 2>&1)
if echo "$output" | grep -q "EPHEMERAL_OK"; then pass "--ephemeral"; else fail "--ephemeral" "unexpected output"; fi

# -o (output to file)
echo "  Testing -o output flag..."
TMPOUT=$(mktemp)
codex exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto -o "$TMPOUT" --skip-git-repo-check "respond with exactly: OUTPUT_OK" 2>&1 >/dev/null
if grep -q "OUTPUT_OK" "$TMPOUT" 2>/dev/null; then pass "-o output file"; else fail "-o output file" "file missing or wrong content"; fi
rm -f "$TMPOUT"

# --json
echo "  Testing --json flag..."
output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto --json --skip-git-repo-check "respond with exactly: JSON_OK" 2>&1)
if echo "$output" | grep -q '"type"'; then pass "--json output"; else fail "--json output" "no JSON events found"; fi

# --search (global flag)
echo "  Testing --search flag..."
output=$(codex --search exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto --skip-git-repo-check "respond with exactly: SEARCH_OK" 2>&1)
if echo "$output" | grep -q "SEARCH_OK"; then pass "--search (global)"; else fail "--search (global)" "unexpected output"; fi

# --add-dir
echo "  Testing --add-dir flag..."
output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto --add-dir /tmp --skip-git-repo-check "respond with exactly: ADDDIR_OK" 2>&1)
if echo "$output" | grep -q "ADDDIR_OK"; then pass "--add-dir"; else fail "--add-dir" "unexpected output"; fi

# ─── Subcommand Tests ───────────────────────────────────────────────

echo ""
echo "=== Subcommands (help check) ==="

for cmd in "review" "resume" "fork" "apply" "cloud" "completion" "features" "mcp-server" "sandbox" "mcp list" "login"; do
  if codex ${cmd} --help &>/dev/null 2>&1; then
    pass "codex ${cmd} --help"
  else
    fail "codex ${cmd} --help" "command not found or errored"
  fi
done

# ─── Model Validation ───────────────────────────────────────────────

echo ""
echo "=== Model Availability ==="

CACHE="$HOME/.codex/models_cache.json"
if [ -f "$CACHE" ]; then
  for model in "gpt-5.4" "gpt-5.4-mini" "gpt-5.3-codex" "gpt-5.2-codex" "gpt-5.1-codex-max"; do
    if grep -q "\"slug\": \"${model}\"" "$CACHE"; then
      pass "model ${model} in cache"
    else
      fail "model ${model}" "not found in models_cache.json"
    fi
  done
else
  skip "model cache" "~/.codex/models_cache.json not found"
fi

# ─── Summary ─────────────────────────────────────────────────────────

echo ""
echo "════════════════════════"
echo "  PASS: ${PASS}  FAIL: ${FAIL}  SKIP: ${SKIP}"
echo "════════════════════════"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
