------------------------------- MODULE Hierarchy -------------------------------
(***************************************************************************)
(* Mechanically verified coherence check for the consistency chain        *)
(* L_0, L_1, L_2, L_3, L_4 over the four formalised anomalies             *)
(* (A_1 stale-generation, A_3 causal-cascade, A_6 tool-effect-reorder,    *)
(* A_2 phantom-tool), aligned with Levels.tla (paper v4_6).               *)
(*                                                                         *)
(* OBLIGATION COUNT (11 theorems, 15 atomic obligations):                 *)
(*   4 adjacent-pair containment theorems  (one obligation each)          *)
(*   6 transitive soundness theorems        (one obligation each)         *)
(*   1 aggregate containment theorem         (five atomic obligations)    *)
(*                                                                         *)
(* SCOPE NOTE.                                                             *)
(* The check is shallow by design. The "direct" soundness claims --- that *)
(* L_i prevents the anomaly introduced at level i --- are tautologies of  *)
(* the level definitions in Levels.tla. For instance L_2(h) is defined as *)
(* L_1(h) /\ CausalCascadeFree(h), so L_2(h) => CausalCascadeFree(h) holds *)
(* by /\-elimination. We do NOT state those as separate TLAPS theorems;   *)
(* the paper cites them by inspection of the definitions.                 *)
(*                                                                         *)
(* The transitive soundness theorems below --- that a stronger level      *)
(* still prevents an anomaly prevented by a weaker ancestor level --- are *)
(* coherence checks discharged by definitional unfolding. They are not    *)
(* deep results; they confirm only that the chosen conjunction structure  *)
(* yields the refinement implications. The substantive correspondence     *)
(* with executable behaviour is established by the Verus mechanisation,   *)
(* not by this module.                                                    *)
(***************************************************************************)

EXTENDS Memory, Anomalies, Levels, TLAPS

(* ------------------------------------------------------------------------ *)
(* Adjacent-pair containment theorems: the 4 cover relations of the chain.  *)
(* ------------------------------------------------------------------------ *)

THEOREM L1_Implies_L0 ==
    \A h \in Seq(OpRecord) : L1(h) => L0(h)
PROOF BY DEF L0, L1

THEOREM L2_Implies_L1 ==
    \A h \in Seq(OpRecord) : L2(h) => L1(h)
PROOF BY DEF L2

THEOREM L3_Implies_L2 ==
    \A h \in Seq(OpRecord) : L3(h) => L2(h)
PROOF BY DEF L3

THEOREM L4_Implies_L3 ==
    \A h \in Seq(OpRecord) : L4(h) => L3(h)
PROOF BY DEF L4

(* ------------------------------------------------------------------------ *)
(* Transitive soundness theorems: 6 inherited preventions.                  *)
(* Each states that a level prevents an anomaly first prevented by a        *)
(* strictly weaker ancestor (the direct preventions are omitted as          *)
(* tautologies, per the scope note above).                                  *)
(* ------------------------------------------------------------------------ *)

THEOREM L2_Prevents_A1 ==
    \A h \in Seq(OpRecord) : L2(h) => StaleGenerationFree(h)
PROOF BY DEF L2, L1

THEOREM L3_Prevents_A1 ==
    \A h \in Seq(OpRecord) : L3(h) => StaleGenerationFree(h)
PROOF BY DEF L3, L2, L1

THEOREM L3_Prevents_A3 ==
    \A h \in Seq(OpRecord) : L3(h) => CausalCascadeFree(h)
PROOF BY DEF L3, L2

THEOREM L4_Prevents_A1 ==
    \A h \in Seq(OpRecord) : L4(h) => StaleGenerationFree(h)
PROOF BY DEF L4, L3, L2, L1

THEOREM L4_Prevents_A3 ==
    \A h \in Seq(OpRecord) : L4(h) => CausalCascadeFree(h)
PROOF BY DEF L4, L3, L2

THEOREM L4_Prevents_A6 ==
    \A h \in Seq(OpRecord) : L4(h) => ToolEffectReorderingFree(h)
PROOF BY DEF L4, L3

(* ------------------------------------------------------------------------ *)
(* Aggregate containment theorem: the 4 cover relations as one statement.   *)
(* TLAPS decomposes this into five atomic obligations (one universal step   *)
(* plus four conjunct obligations).                                         *)
(* ------------------------------------------------------------------------ *)

THEOREM ChainCoherence ==
    \A h \in Seq(OpRecord) :
        /\ L1(h) => L0(h)
        /\ L2(h) => L1(h)
        /\ L3(h) => L2(h)
        /\ L4(h) => L3(h)
PROOF
  <1> TAKE h \in Seq(OpRecord)
  <1>1. L1(h) => L0(h) BY DEF L0, L1
  <1>2. L2(h) => L1(h) BY DEF L2
  <1>3. L3(h) => L2(h) BY DEF L3
  <1>4. L4(h) => L3(h) BY DEF L4
  <1> QED BY <1>1, <1>2, <1>3, <1>4

==========================================================================
