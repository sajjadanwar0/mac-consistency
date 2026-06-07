------------------------- MODULE Anomalies_A3_redef -------------------------
(***************************************************************************)
(* A_3 REDEFINITION (Option A).                                            *)
(*                                                                         *)
(* Drop these definitions into Anomalies.tla, REPLACING the old            *)
(* CausalCascade (the "unsupported committed read" residue). The old       *)
(* predicate fired in benign serial executions (a read of an initial /     *)
(* seeded / externally-supplied value that no logged op wrote), so no       *)
(* runtime could prevent it -- "L2 prevents A3" only ever held for the      *)
(* cascade-abort condition below. We promote that condition to be the       *)
(* catalogued A_3, matching lib_l2_safety.rs::a3_witness exactly.           *)
(*                                                                         *)
(* OpRecord must now additionally carry:                                   *)
(*    aborted : BOOLEAN                                                     *)
(*    preds   : SUBSET (1 .. Len(h))   (* the ops whose committed writes    *)
(*                                         this op observed: causal closure *)
(*                                         at read time, writer's own preds *)
(*                                         unioned in -- see L2 model *)     *)
(***************************************************************************)
EXTENDS Naturals, Sequences

CONSTANT NULL

(* --- Catalogued A_3: precise cascade-abort predicate. ---                *)
(* Trace image of lib_l2_safety.rs::a3_witness: a SURVIVING (committed,     *)
(* non-aborted) operation retains in its causal closure a predecessor that  *)
(* was ABORTED -- its basis was retracted and it was not compensated.       *)
CausalCascade(h) ==
    \E j \in 1 .. Len(h), p \in 1 .. Len(h) :
        /\ ~ h[j].aborted
        /\ p \in h[j].preds
        /\ h[p].aborted

(* --- Retained flat-trace detector: a SOUND over-approximation. ---       *)
(* For black-box / un-instrumented traces that do not expose preds/aborted. *)
(* Theorem (paper Sec. A3): CausalCascade(h) => CausalCascadeResidue(proj),  *)
(* i.e. every genuine cascade leaves a residue witness. The converse fails:  *)
(* the residue also fires on reads of un-logged initial values.            *)
CausalCascadeResidue(h) ==
    \E j \in 1 .. Len(h) :
        \E c \in h[j].read_set :
            /\ h[j].read_values[c] # NULL
            /\ \A k \in 1 .. Len(h) :
                 (k # j) =>
                   ~ ( /\ c \in h[k].write_set
                       /\ h[k].write_time =< h[j].read_time
                       /\ h[k].write_values[c] = h[j].read_values[c] )

(***************************************************************************)
(* TLC WITNESS for the new CausalCascade (2-op history; trivially found).  *)
(*                                                                         *)
(*   op1 : commits a write of c1 = v1, then ABORTS    (aborted = TRUE)      *)
(*   op2 : reads c1 = v1, has 1 \in preds, COMMITS    (aborted = FALSE)     *)
(*                                                                         *)
(* Then ~op2.aborted /\ 1 \in op2.preds /\ op1.aborted  ==> CausalCascade.  *)
(*                                                                         *)
(* Check, e.g., with invariant  Inv == ~CausalCascade(h)  over the          *)
(* abort-annotated history generator; TLC returns the 2-op counterexample.  *)
(* The OLD residue witness (committed read of v1 with no committed          *)
(* producer at/<= read time) remains the witness for CausalCascadeResidue.  *)
(***************************************************************************)

(* Levels.tla is unchanged in shape; L2 now reads against the precise A_3:  *)
(*    L2(h) == L1(h) /\ ~CausalCascade(h)                                    *)
(* and lib_l2_safety.rs::lemma_l2_reachable_no_a3 ALREADY proves             *)
(* ~CausalCascade on every reachable L2 state (no new Verus required).       *)
=============================================================================
