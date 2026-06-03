---- MODULE M_L5_CausalCascade ----
EXTENDS Memory, Anomalies, Levels

NoCoOccurrence == ~(L5(log) /\ CausalCascade(log))

================================================================================
