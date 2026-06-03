---- MODULE MC_A3NotA6 ----
\* Mechanises Theorem 5.3 part 1: ∃h. A_3(h) ∧ ¬A_6(h).
\* TLC violates A3ImpliesA6, producing the witness.

EXTENDS Memory, Anomalies

A3ImpliesA6 == CausalCascade(log) => ToolEffectReordering(log)

====
