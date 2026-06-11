---------------------------------- MODULE MC_A3 ----------------------------------
(* Witness harness for the A_3 flat-trace RESIDUE (Causal-Cascade residue).      *)
(*                                                                                *)
(* Paper Sec. 3.3 splits A_3 into two predicates:                                 *)
(*   - CausalCascade: the precise cascade-abort condition (Definition 3), whose   *)
(*     two-operation abort-annotated witness is checked by A3_witness_check.tla   *)
(*     (a self-contained harness; PASS = TLC reports no error);                   *)
(*   - CausalCascadeResidue: the flat-trace sound over-approximation the verified *)
(*     detector decides — a committed read of a value no committed write produced *)
(*     at or before the read.                                                     *)
(* THIS harness exhibits the residue witness over the Memory state machine: with  *)
(* AllowSkew = TRUE an agent may record an unsupported read value (commit-log     *)
(* skew), and TLC violates the invariant below with exactly that history. The     *)
(* Memory machine has no abort transition, so the precise CausalCascade is        *)
(* (correctly) unreachable here; its witness lives in A3_witness_check.            *)
EXTENDS Memory, Anomalies

NoCausalCascadeResidue == ~CausalCascadeResidue(log)
================================================================================
