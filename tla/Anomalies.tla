------------------------------- MODULE Anomalies -------------------------------
EXTENDS Memory

\* A1. Stale-Generation
StaleGeneration(history) ==
    \E i, j \in 1..Len(history) :
        /\ i # j
        /\ history[i].agent # history[j].agent
        /\ \E c \in history[i].read_set \cap history[j].write_set :
              /\ history[i].read_time < history[j].write_time
              /\ history[j].write_time < history[i].write_time
              /\ history[i].read_values[c] # history[j].write_values[c]

\* A2. Phantom-Tool (TODO Week 1)
PhantomTool(history) == FALSE

\* A3. Causal-Cascade (TODO Week 2)
CausalCascade(history) == FALSE

\* A4. Split-View (TODO Week 2 - requires replication extension)
SplitView(history) == FALSE

\* A5. Long-Generation Window (TODO Week 3)
LongGeneration(history) == FALSE

\* A6. Tool-Effect Reordering (TODO Week 3 - requires sub-operations)
ToolEffectReordering(history) == FALSE

================================================================================
