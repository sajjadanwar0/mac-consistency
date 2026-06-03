---- MODULE M_L5_PhantomTool ----
EXTENDS Memory, Anomalies, Levels

NoCoOccurrence == ~(L5(log) /\ PhantomTool(log))

================================================================================
