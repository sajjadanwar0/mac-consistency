---- MODULE M_L5_StaleGeneration ----
EXTENDS Memory, Anomalies, Levels

NoCoOccurrence == ~(L5(log) /\ StaleGeneration(log))

================================================================================
