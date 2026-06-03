---------------------------------- MODULE MC_A1 ----------------------------------
(* Model-checking harness for anomaly A1 (Stale-Generation).
   TLC violates NoStaleGen to produce the canonical A1 witness. *)
EXTENDS Memory, Anomalies

NoStaleGen == ~StaleGeneration(log)
================================================================================
