#!/bin/bash
# =====================================================================
# tlc_bounds_expansion.sh
# Run TLC at expanded bounds across the v4_6-relevant MC harnesses.
#
# Usage:
#   bash tlc_bounds_expansion.sh
#
# Environment:
#   TLC      — TLC binary (default: tlc)
#   TIMEOUT  — per-run timeout in seconds (default: 600 = 10 min)
#   WORKERS  — TLC worker threads (default: 4)
#
# Run from your mac-consistency repo root.
# =====================================================================

set -u

TLC=${TLC:-tlc}
TIMEOUT=${TIMEOUT:-600}
WORKERS=${WORKERS:-4}

if [ ! -d tla ]; then
    echo "ERROR: run from mac-consistency repo root (no ./tla directory)"
    exit 1
fi

if ! command -v "$TLC" >/dev/null 2>&1; then
    echo "ERROR: TLC binary not found: $TLC"
    echo "       Set TLC env var to the path of your TLC binary."
    echo "       Example: TLC=/usr/local/bin/tla2tools-tlc.sh bash $0"
    exit 1
fi

mkdir -p tlc_results
SUMMARY=tlc_results/summary.csv
echo "Harness,Variant,DistinctStates,Depth,TimeSec,Outcome" > "$SUMMARY"

# ---------------------------------------------------------------------
# v4_6-relevant MC harnesses
# (skip MC_A5_witness, MC_L3a_NotL3b, MC_L3b_NotL3a — v5-specific)
# ---------------------------------------------------------------------
HARNESSES=(
    MC_A1_witness
    MC_A2_witness
    MC_A3_witness
    MC_A6_witness
    MC_A1_struct
    MC_CodeCRDT_RYW
    MC_CodeCRDT_AdmitsA1
)

# ---------------------------------------------------------------------
# Generate _medium.cfg and _large.cfg by sed-substituting Agents/MaxOps
# ---------------------------------------------------------------------
generate_cfg() {
    local src=$1 dst=$2 agents=$3 maxops=$4
    cp "$src" "$dst"
    # Substitute Agents = {...} → Agents = $agents (with proper escaping)
    sed -i "s|^\\([[:space:]]*\\)Agents[[:space:]]*=.*|\\1Agents = ${agents}|" "$dst"
    # Substitute MaxOps = N → MaxOps = $maxops
    sed -i "s|^\\([[:space:]]*\\)MaxOps[[:space:]]*=.*|\\1MaxOps = ${maxops}|" "$dst"
}

# ---------------------------------------------------------------------
# Run TLC and parse results
# ---------------------------------------------------------------------
run_tlc() {
    local harness=$1 variant=$2 cfg=$3
    local cfg_base=$(basename "$cfg")
    local log="$(pwd)/tlc_results/${harness}_${variant}.log"

    local start=$(date +%s)
    (cd tla && timeout "$TIMEOUT" "$TLC" -workers "$WORKERS" -config "$cfg_base" "$harness") > "$log" 2>&1
    local ec=$?
    local end=$(date +%s)
    local elapsed=$((end - start))

    # Parse TLC summary line: "X states generated, Y distinct states found at depth Z"
    local distinct depth
    distinct=$(grep -oE "[0-9]+ distinct states found" "$log" 2>/dev/null | tail -1 | grep -oE "^[0-9]+")
    depth=$(grep -oE "depth [0-9]+" "$log" 2>/dev/null | tail -1 | grep -oE "[0-9]+$")
    distinct=${distinct:-?}
    depth=${depth:-?}

    local outcome
    if [ $ec = 124 ]; then
        outcome="TIMEOUT(${TIMEOUT}s)"
    elif grep -q "is violated" "$log" 2>/dev/null; then
        outcome="WITNESS_FOUND"
    elif grep -q "No error has been found" "$log" 2>/dev/null; then
        outcome="EXHAUSTIVE_OK"
    elif grep -qE "(Out of memory|OutOfMemoryError|java.lang.OutOfMemory)" "$log" 2>/dev/null; then
        outcome="OOM"
    elif [ $ec = 0 ]; then
        outcome="OK(ec=0)"
    else
        outcome="ERROR(ec=$ec)"
    fi

    printf "  %-9s  %-12s  %-7s  %5ds  %s\n" "$variant" "$distinct" "$depth" "$elapsed" "$outcome"
    echo "$harness,$variant,$distinct,$depth,$elapsed,$outcome" >> "$SUMMARY"
}

# ---------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------
echo "TLC bounds expansion — paper v4_6"
echo "TLC=$TLC  TIMEOUT=${TIMEOUT}s  WORKERS=$WORKERS"
echo

for harness in "${HARNESSES[@]}"; do
    base="tla/${harness}.cfg"
    if [ ! -f "$base" ]; then
        echo "$harness: SKIP (no $base)"
        continue
    fi

    medium="tla/${harness}_medium.cfg"
    large="tla/${harness}_large.cfg"

    # Medium: |A|=3, MaxOps=6
    generate_cfg "$base" "$medium" "{a1, a2, a3}" "6"
    # Large:  |A|=3, MaxOps=9
    generate_cfg "$base" "$large"  "{a1, a2, a3}" "9"

    echo "$harness:"
    printf "  %-9s  %-12s  %-7s  %5s   %s\n" "variant" "distinct" "depth" "time" "outcome"
    run_tlc "$harness" baseline "$base"
    run_tlc "$harness" medium   "$medium"
    run_tlc "$harness" large    "$large"
    echo
done

echo "==================================================="
echo "Done. Summary at:  $SUMMARY"
echo "Per-run logs at:   tlc_results/*.log"
echo
echo "Quick summary:"
column -t -s, "$SUMMARY"