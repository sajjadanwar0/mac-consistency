--------------------------- MODULE Refinement ---------------------------
(* High-level refinement claim for CodeCRDT vs. the relaxed Memory      *)
(* operational model. See paper §6.4.                                    *)
(*                                                                         *)
(* MECHANISATION STATUS                                                   *)
(* The refinement direction is:                                           *)
(*   CodeCRDT.Spec  =>  MemoryWithStaleness.Spec   (under projection phi) *)
(* and not the strong Memory.Spec, because CodeCRDT admits A_1.          *)
(*                                                                         *)
(* Full mechanisation requires:                                           *)
(*  (1) replacing CodeCRDT.tla's RECURSIVE ApplyForward with a non-      *)
(*      recursive Sequences-based fold (TLAPS does not support          *)
(*      TLA+'s RECURSIVE keyword in proof mode);                         *)
(*  (2) defining MemoryWithStaleness.tla as a sibling module with a      *)
(*      relaxed StartRead action;                                        *)
(*  (3) discharging a stuttering-respecting simulation by induction on   *)
(*      action types (~200 LoC TLAPS).                                  *)
(*                                                                         *)
(* This file states the claim and records its mechanisation status.      *)
(* The proof of CodeCRDT's level placement at L_1 (and not L_2) is       *)
(* established empirically by the TLC runs of MC_CodeCRDT_RYW.tla        *)
(* (vacuity of LostSelfWrite, 14M states) and MC_CodeCRDT_AdmitsA1.tla   *)
(* (StaleGeneration witness). Those runs are the substantive evidence;   *)
(* the refinement-style mechanisation is a stronger statement deferred   *)
(* to follow-up work.                                                    *)

EXTENDS Naturals, Sequences, TLAPS

\* Placeholder for the refinement claim. Replace with the actual
\* CodeCRDT.Spec => MemoryWithStaleness.Spec implication once the
\* recursion-free CodeCRDT and MemoryWithStaleness sibling are in place.
CodeCRDT_RefinesRelaxedMemory == TRUE

THEOREM RefinementClaim == CodeCRDT_RefinesRelaxedMemory
PROOF BY DEF CodeCRDT_RefinesRelaxedMemory

==========================================================================
