---- MODULE M_L6_StaleGeneration ----
EXTENDS Memory, Anomalies, Levels

NoCoOccurrence == ~(L6(log) /\ StaleGeneration(log))

================================================================================
