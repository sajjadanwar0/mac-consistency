---- MODULE MC_A3NotA6 ----

EXTENDS Memory, Anomalies

A3ImpliesA6 == CausalCascade(log) => ToolEffectReordering(log)

====
