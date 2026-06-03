#!/bin/bash
# parse_tlc_logs.sh
# Re-parse existing TLC logs in tlc_results/ with accurate (comma-aware) regex.
# Does NOT re-run TLC. Just produces a corrected summary.

set -u

if [ ! -d tlc_results ]; then
    echo "ERROR: no tlc_results/ directory. Run from mac-consistency repo root."
    exit 1
fi

cd tlc_results
out=summary_v2.csv

echo "Harness,Variant,DistinctStates,Depth,Outcome,Notes" > "$out"

for log in MC_*.log; do
    [ -f "$log" ] || continue
    name="${log%.log}"

    # Split MC_<harness>_<variant>
    variant=$(echo "$name" | grep -oE "(baseline|medium|large)$" || echo "?")
    harness=$(echo "$name" | sed -E "s/_${variant}$//")

    # Parse distinct states — strip commas, handle "N,NNN,NNN distinct states found"
    distinct=$(grep "distinct states found" "$log" | tail -1 | \
        awk '{
            for (i = 1; i <= NF; i++) {
                if ($i == "distinct" && $(i+1) == "states") {
                    gsub(",", "", $(i-1));
                    print $(i-1);
                    exit
                }
            }
        }')
    distinct=${distinct:-?}

    # Parse depth — try completion line first, fall back to last Progress
    depth=$(grep -oE "depth of the complete state graph search is [0-9]+" "$log" \
            | grep -oE "[0-9]+$")
    if [ -z "$depth" ]; then
        depth=$(grep -oE "Progress\([0-9]+\)" "$log" | tail -1 | grep -oE "[0-9]+")
    fi
    depth=${depth:-?}

    # Determine outcome
    notes=""
    if grep -q "is violated" "$log"; then
        outcome="WITNESS_FOUND"
    elif grep -q "Model checking completed" "$log"; then
        outcome="EXHAUSTIVE_OK"
    elif grep -qE "(Parsing or semantic analysis failed|Semantic errors)" "$log"; then
        outcome="PARSE_ERROR"
        # Capture the error line
        notes=$(grep -oE "The operator .* requires .* arguments\." "$log" | head -1)
    elif grep -qE "(Out of memory|OutOfMemoryError)" "$log"; then
        outcome="OOM"
    elif grep -q "Progress" "$log" && ! grep -q "completed" "$log"; then
        outcome="PARTIAL_TIMEOUT"
        # Add "(no violation found in N states)"
        notes="no violation in ${distinct} distinct states"
    else
        outcome="UNKNOWN"
    fi

    printf "%s,%s,%s,%s,%s,%s\n" "$harness" "$variant" "$distinct" "$depth" "$outcome" "$notes" >> "$out"
done

cd ..

echo "Summary written to: tlc_results/$out"
echo
column -t -s, "tlc_results/$out"