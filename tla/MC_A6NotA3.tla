---- MODULE MC_A6NotA3 ----
\* Mechanises Theorem 5.3 part 2: ∃h. A_6(h) ∧ ¬A_3(h).
\* TLC violates A6ImpliesA3, producing the witness.

EXTENDS Memory, Anomalies

A6ImpliesA3 == ToolEffectReordering(log) => CausalCascade(log)

====
