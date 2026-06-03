---- MODULE M_L6_CausalCascade ----
EXTENDS Memory, Anomalies, Levels

NoCoOccurrence == ~(L6(log) /\ CausalCascade(log))

================================================================================
