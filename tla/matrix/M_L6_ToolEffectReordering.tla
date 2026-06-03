---- MODULE M_L6_ToolEffectReordering ----
EXTENDS Memory, Anomalies, Levels

NoCoOccurrence == ~(L6(log) /\ ToolEffectReordering(log))

================================================================================
