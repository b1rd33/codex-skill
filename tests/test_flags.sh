#!/usr/bin/env bash
# Test suite for codex-skill — validates all CLI flags, presets, and subcommands
# Usage: ./tests/test_flags.sh [--quick]
# Requires: codex CLI installed and authenticated
#
# --quick: skip live codex exec calls (only test help/models/flags)

PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }
skip() { echo "  SKIP: $1 — $2"; SKIP=$((SKIP + 1)); }

QUICK=false
[[ "${1:-}" == "--quick" ]] && QUICK=true

# Check codex is installed
if ! command -v codex &>/dev/null; then
  echo "ERROR: codex CLI not found. Install with: npm i -g @openai/codex"
  exit 1
fi

VERSION=$(codex --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo 'unknown')
echo "Testing codex-cli ${VERSION}"
echo ""

# ─── Subcommand Tests (instant, no auth needed) ─────────────────────

echo "=== Subcommands (help check) ==="

for cmd in exec review resume fork apply cloud completion features mcp-server sandbox login logout debug app; do
  if codex ${cmd} --help &>/dev/null 2>&1; then
    pass "codex ${cmd} --help"
  else
    fail "codex ${cmd} --help" "command not found or errored"
  fi
done

# ─── MCP Subcommands ────────────────────────────────────────────────

echo ""
echo "=== MCP Subcommands ==="

for cmd in "mcp list --help" "mcp get --help" "mcp add --help" "mcp remove --help" "mcp login --help" "mcp logout --help"; do
  if codex ${cmd} &>/dev/null 2>&1; then
    pass "codex ${cmd}"
  else
    fail "codex ${cmd}" "command not found or errored"
  fi
done

# ─── Cloud Subcommands ──────────────────────────────────────────────

echo ""
echo "=== Cloud Subcommands ==="

for cmd in "cloud exec --help" "cloud status --help" "cloud list --help" "cloud apply --help" "cloud diff --help"; do
  if codex ${cmd} &>/dev/null 2>&1; then
    pass "codex ${cmd}"
  else
    fail "codex ${cmd}" "command not found or errored"
  fi
done

# ─── Feature Flags ──────────────────────────────────────────────────

echo ""
echo "=== Feature Flags ==="

if codex features list &>/dev/null 2>&1; then
  pass "codex features list"
  for feature in fast_mode multi_agent enable_request_compression; do
    if codex features list 2>&1 | grep -q "${feature}"; then
      pass "feature ${feature} exists"
    else
      fail "feature ${feature}" "not in features list"
    fi
  done
else
  fail "codex features list" "command failed"
fi

# ─── Exec Flag Acceptance (--help check, no live calls) ─────────────

echo ""
echo "=== Exec Flags (help parse) ==="

EXEC_HELP=$(codex exec --help 2>&1)
for flag in "--full-auto" "--ephemeral" "--json" "--output-schema" "--add-dir" "--skip-git-repo-check" "--color" "--progress-cursor" "--oss" "--image" "--profile" "--sandbox"; do
  if echo "$EXEC_HELP" | grep -q -- "${flag}"; then
    pass "exec flag ${flag}"
  else
    fail "exec flag ${flag}" "not in exec --help"
  fi
done

# Global flags
GLOBAL_HELP=$(codex --help 2>&1)
for flag in "--search" "--no-alt-screen" "--ask-for-approval" "--dangerously-bypass"; do
  if echo "$GLOBAL_HELP" | grep -q -- "${flag}"; then
    pass "global flag ${flag}"
  else
    fail "global flag ${flag}" "not in codex --help"
  fi
done

# ─── Model Validation ───────────────────────────────────────────────

echo ""
echo "=== Model Availability ==="

CACHE="$HOME/.codex/models_cache.json"
if [ -f "$CACHE" ]; then
  for model in "gpt-5.4" "gpt-5.4-mini" "gpt-5.3-codex" "gpt-5.2-codex" "gpt-5.2" "gpt-5.1-codex-max"; do
    if grep -q "\"slug\": \"${model}\"" "$CACHE"; then
      pass "model ${model}"
    else
      fail "model ${model}" "not found in models_cache.json"
    fi
  done
else
  skip "model cache" "~/.codex/models_cache.json not found"
fi

# ─── Login Subcommands ──────────────────────────────────────────────

echo ""
echo "=== Auth Commands ==="

LOGIN_HELP=$(codex login --help 2>&1)
if echo "$LOGIN_HELP" | grep -q -- "--with-api-key"; then
  pass "codex login --with-api-key"
else
  fail "codex login --with-api-key" "flag not found"
fi

if codex login status --help &>/dev/null 2>&1; then
  pass "codex login status --help"
else
  fail "codex login status --help" "subcommand not found"
fi

# ─── Live Preset Tests (skip with --quick) ───────────────────────────

if $QUICK; then
  echo ""
  echo "=== Live Tests SKIPPED (--quick mode) ==="
  skip "live preset tests" "use without --quick to run"
else
  echo ""
  echo "=== Live Preset Tests (requires auth + API credits) ==="

  run_preset() {
    local name="$1" effort="$2" token="$3"
    echo "  Testing ${name} preset (${effort} effort)..."
    local output
    output=$(codex --search exec -m gpt-5.4 -c model_reasoning_effort="${effort}" --full-auto --skip-git-repo-check "respond with exactly: ${token}" 2>&1) || true
    if echo "$output" | grep -q "${token}"; then
      pass "${name} preset"
    else
      fail "${name} preset" "expected ${token}"
    fi
  }

  run_preset "turbo" "low" "TURBO_OK"
  run_preset "balanced" "medium" "BALANCED_OK"
  run_preset "quality" "high" "QUALITY_OK"
  run_preset "max" "xhigh" "MAX_OK"

  echo ""
  echo "=== Live Sandbox Tests ==="

  echo "  Testing read-only sandbox..."
  output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" -s read-only --skip-git-repo-check "respond with exactly: READONLY_OK" 2>&1) || true
  if echo "$output" | grep -q "READONLY_OK"; then pass "read-only sandbox"; else fail "read-only sandbox" "unexpected output"; fi

  echo "  Testing workspace-write sandbox..."
  output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" -s workspace-write --full-auto --skip-git-repo-check "respond with exactly: WRITE_OK" 2>&1) || true
  if echo "$output" | grep -q "WRITE_OK"; then pass "workspace-write sandbox"; else fail "workspace-write sandbox" "unexpected output"; fi

  echo ""
  echo "=== Live Flag Tests ==="

  echo "  Testing -a global flag positioning..."
  output=$(codex -a on-request exec -m gpt-5.4 -c model_reasoning_effort="low" -s read-only --skip-git-repo-check "respond with exactly: APPROVAL_OK" 2>&1) || true
  if echo "$output" | grep -q "APPROVAL_OK"; then pass "-a before exec"; else fail "-a before exec" "unexpected output"; fi

  echo "  Testing --ephemeral..."
  output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto --ephemeral --skip-git-repo-check "respond with exactly: EPHEMERAL_OK" 2>&1) || true
  if echo "$output" | grep -q "EPHEMERAL_OK"; then pass "--ephemeral"; else fail "--ephemeral" "unexpected output"; fi

  echo "  Testing -o output file..."
  TMPOUT=$(mktemp)
  codex exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto -o "$TMPOUT" --skip-git-repo-check "respond with exactly: OUTPUT_OK" 2>&1 >/dev/null || true
  if grep -q "OUTPUT_OK" "$TMPOUT" 2>/dev/null; then pass "-o output file"; else fail "-o output file" "file missing or wrong content"; fi
  rm -f "$TMPOUT"

  echo "  Testing --json output..."
  output=$(codex exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto --json --skip-git-repo-check "respond with exactly: JSON_OK" 2>&1) || true
  if echo "$output" | grep -q '"type"'; then pass "--json output"; else fail "--json output" "no JSON events found"; fi
fi

# ─── Summary ─────────────────────────────────────────────────────────

echo ""
echo "════════════════════════"
echo "  PASS: ${PASS}  FAIL: ${FAIL}  SKIP: ${SKIP}"
echo "════════════════════════"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
