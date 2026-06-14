---- MODULE MC_A6NotA3 ----

EXTENDS Memory, Anomalies

A6ImpliesA3 == ToolEffectReordering(log) => CausalCascade(log)

====
