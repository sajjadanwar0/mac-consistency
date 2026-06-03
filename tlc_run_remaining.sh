#!/bin/bash
# =====================================================================
# tlc_run_remaining.sh
# Run TLC at three bound levels for:
#   MC_A1, MC_A2, MC_A3, MC_A6   — witness harnesses
#   MC_A1_struct                  — snapshot-insufficiency observation
#
# CodeCRDT_RYW and CodeCRDT_AdmitsA1 were already verified in earlier
# runs and are skipped here.
#
# Run from mac-consistency repo root:
#   bash tlc_run_remaining.sh
#
# Environment overrides:
#   TLC      — TLC binary (default: tlc)
#   TIMEOUT  — seconds per run (default: 300 = 5 min; witnesses are fast)
#   WORKERS  — TLC worker threads (default: 4)
# =====================================================================

set -u
TLC=${TLC:-tlc}
TIMEOUT=${TIMEOUT:-300}
WORKERS=${WORKERS:-4}

[ ! -d tla ] && { echo "ERROR: run from repo root"; exit 1; }
mkdir -p tlc_results

HARNESSES=(MC_A1 MC_A2 MC_A3 MC_A6 MC_A1_struct)

# ---------------------------------------------------------------------
# Generate _medium.cfg and _large.cfg by sed-substituting Agents/MaxOps
# ---------------------------------------------------------------------
generate_cfg() {
    local src=$1 dst=$2 agents=$3 maxops=$4
    cp "$src" "$dst"
    sed -i "s|^\\([[:space:]]*\\)Agents[[:space:]]*=.*|\\1Agents = ${agents}|" "$dst"
    sed -i "s|^\\([[:space:]]*\\)MaxOps[[:space:]]*=.*|\\1MaxOps = ${maxops}|" "$dst"
}

# ---------------------------------------------------------------------
# Run TLC and parse output (comma-aware)
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

    local distinct
    distinct=$(grep "distinct states found" "$log" 2>/dev/null | tail -1 | awk '{
        for (i = 1; i <= NF; i++) {
            if ($i == "distinct" && $(i+1) == "states") {
                gsub(",", "", $(i-1));
                print $(i-1);
                exit
            }
        }
    }')
    distinct=${distinct:-?}

    local depth
    depth=$(grep -oE "depth of the complete state graph search is [0-9]+" "$log" 2>/dev/null | grep -oE "[0-9]+$")
    if [ -z "${depth:-}" ]; then
        depth=$(grep -oE "Progress\([0-9]+\)" "$log" 2>/dev/null | tail -1 | grep -oE "[0-9]+")
    fi
    depth=${depth:-?}

    local outcome
    if [ $ec = 124 ]; then
        outcome="TIMEOUT(${TIMEOUT}s)"
    elif grep -q "is violated" "$log" 2>/dev/null; then
        outcome="WITNESS_FOUND"
    elif grep -q "Model checking completed" "$log" 2>/dev/null; then
        outcome="EXHAUSTIVE_OK"
    elif grep -qE "(Out of memory|OutOfMemoryError)" "$log" 2>/dev/null; then
        outcome="OOM"
    elif grep -qE "Error: The invariant .* is not defined" "$log" 2>/dev/null; then
        outcome="CFG_INVARIANT_MISSING"
    elif grep -qE "(Parsing or semantic analysis failed|Semantic errors)" "$log" 2>/dev/null; then
        outcome="PARSE_ERROR"
    else
        outcome="ERROR(ec=$ec)"
    fi

    printf "  %-9s  %-12s  %-7s  %5ds  %s\n" "$variant" "$distinct" "$depth" "$elapsed" "$outcome"
    echo "$harness,$variant,$distinct,$depth,$elapsed,$outcome" >> tlc_results/summary_remaining.csv
}

echo "TLC remaining harnesses — paper v4_6"
echo "TLC=$TLC  TIMEOUT=${TIMEOUT}s  WORKERS=$WORKERS"
echo

echo "Harness,Variant,DistinctStates,Depth,TimeSec,Outcome" > tlc_results/summary_remaining.csv

for h in "${HARNESSES[@]}"; do
    base="tla/${h}.cfg"
    if [ ! -f "$base" ]; then
        echo "$h: SKIP (no $base)"
        continue
    fi
    medium="tla/${h}_medium.cfg"
    large="tla/${h}_large.cfg"
    generate_cfg "$base" "$medium" "{a1, a2, a3}" "6"
    generate_cfg "$base" "$large"  "{a1, a2, a3}" "9"

    echo "$h:"
    printf "  %-9s  %-12s  %-7s  %6s   %s\n" "variant" "distinct" "depth" "time" "outcome"
    run_tlc "$h" baseline "$base"
    run_tlc "$h" medium   "$medium"
    run_tlc "$h" large    "$large"
    echo
done

echo "==============================================="
echo "Done. Summary: tlc_results/summary_remaining.csv"
echo
column -t -s, tlc_results/summary_remaining.csv