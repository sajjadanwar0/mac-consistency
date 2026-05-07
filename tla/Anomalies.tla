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

\* A2. Phantom-Tool
\*   An agent observes a tool t in the registry at read_time, plans to use
\*   it, but t is no longer in the registry at write_time.
PhantomTool(history) ==
    \E i \in 1..Len(history) :
        /\ history[i].planned_tool # NULL
        /\ history[i].planned_tool \in history[i].read_registry
        /\ history[i].planned_tool \notin history[i].write_registry

\* A3. Causal-Cascade (TODO Week 2)
CausalCascade(history) == FALSE

\* A4. Split-View (TODO Week 2)
SplitView(history) == FALSE

\* A5. Long-Generation Window (TODO Week 3)
LongGeneration(history) == FALSE

\* A6. Tool-Effect Reordering (TODO Week 3)
ToolEffectReordering(history) == FALSE

================================================================================
