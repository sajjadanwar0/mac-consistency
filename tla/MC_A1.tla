---------------------------------- MODULE MC_A1 ----------------------------------
(* Model-checking harness for anomaly A1 (Stale-Generation).
   Runs the Memory state machine and asserts that StaleGeneration never holds.
   TLC will produce a counter-example: the canonical witness for A1. *)

EXTENDS Memory, Anomalies

\* The invariant TLC will try to violate.
\* When violated, the resulting error trace IS the A1 witness.
StaleGenerationFree == ~StaleGeneration(log)

================================================================================
