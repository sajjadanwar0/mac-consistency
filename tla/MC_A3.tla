---------------------------------- MODULE MC_A3 ----------------------------------
(* Witness harness for A3 (Causal-Cascade). *)
EXTENDS Memory, Anomalies

NoCausalCascade == ~CausalCascade(log)
================================================================================
