------------------------------- MODULE Anomalies -------------------------------
EXTENDS Memory

\* A1. Stale-Generation
\*   Read context becomes stale DURING the operation's generation window.
StaleGeneration(history) ==
    \E i, j \in 1..Len(history) :
        /\ i # j
        /\ history[i].agent # history[j].agent
        /\ \E c \in history[i].read_set \cap history[j].write_set :
              /\ history[i].read_time < history[j].write_time
              /\ history[j].write_time < history[i].write_time
              /\ history[i].read_values[c] # history[j].write_values[c]

\* A2. Phantom-Tool
PhantomTool(history) ==
    \E i \in 1..Len(history) :
        /\ history[i].planned_tool # NULL
        /\ history[i].planned_tool \in history[i].read_registry
        /\ history[i].planned_tool \notin history[i].write_registry

\* A3. Causal-Cascade
\*   An op produced an external effect and its read context was retracted
\*   AFTER the external commit. Distinct from A1: the retraction happens
\*   post-write, so the external effect persists with no current grounding.
CausalCascade(history) ==
    \E j \in 1..Len(history) :
        /\ history[j].write_set \cap ExternalCells # {}
        /\ \E c \in history[j].read_set :
              /\ c \notin ExternalCells
              /\ \E k \in 1..Len(history) :
                    /\ k # j
                    /\ c \in history[k].write_set
                    /\ history[k].write_time > history[j].write_time   \* tightened
                    /\ history[k].write_values[c] # history[j].read_values[c]

\* A4. Split-View (TODO Week 3)
SplitView(history) == FALSE

\* A5. Long-Generation Window
LongGeneration(history) ==
    \E i \in 1..Len(history) :
        \E j, k \in 1..Len(history) :
            /\ j # k /\ j # i /\ k # i
            /\ history[j].write_time > history[i].read_time
            /\ history[j].write_time < history[i].write_time
            /\ history[k].write_time > history[i].read_time
            /\ history[k].write_time < history[i].write_time
            /\ history[j].write_set \cap history[i].read_set # {}
            /\ history[k].write_set \cap history[i].read_set # {}

\* A6. Tool-Effect Reordering (TODO Week 3)
ToolEffectReordering(history) == FALSE

================================================================================
