---- MODULE M_L5_ToolEffectReordering ----
EXTENDS Memory, Anomalies, Levels

NoCoOccurrence == ~(L5(log) /\ ToolEffectReordering(log))

================================================================================
