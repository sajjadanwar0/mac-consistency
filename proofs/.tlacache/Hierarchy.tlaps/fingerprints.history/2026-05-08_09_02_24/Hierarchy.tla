------------------------------- MODULE Hierarchy -------------------------------
(***************************************************************************)
(* Mechanically verified hierarchy theorems for the consistency levels    *)
(* L0 through L6 over the anomaly catalogue.                              *)
(*                                                                          *)
(* SCOPE NOTE.                                                             *)
(* The "direct" soundness claims — that L_i prevents the specific anomaly *)
(* added at level i — are tautologies of the level definitions in         *)
(* Levels.tla. For instance, L2(h) is defined as ~A1(h) /\ ~A5(h), so   *)
(* L2(h) => ~A1(h) holds by /\-elimination. We do not state these as    *)
(* TLAPS theorems; the paper cites them by inspection of the              *)
(* definitions.                                                           *)
(*                                                                          *)
(* The "transitive" soundness theorems below — that stronger levels      *)
(* prevent all anomalies prevented by weaker levels — are non-trivial    *)
(* (they require chaining definition expansions) and are discharged       *)
(* mechanically.                                                          *)
(***************************************************************************)

EXTENDS Memory, Anomalies, Levels, TLAPS

(* ------------------------------------------------------------------------ *)
(* Containment theorems                                                       *)
(* ------------------------------------------------------------------------ *)

THEOREM L1_Implies_L0 ==
    \A h \in Seq(OpRecord) : L1(h) => L0(h)
PROOF BY DEF L0, L1

THEOREM L2_Implies_L1 ==
    \A h \in Seq(OpRecord) : L2(h) => L1(h)
PROOF BY DEF L1

THEOREM L3_Implies_L2 ==
    \A h \in Seq(OpRecord) : L3(h) => L2(h)
PROOF BY DEF L3

THEOREM L4_Implies_L3 ==
    \A h \in Seq(OpRecord) : L4(h) => L3(h)
PROOF BY DEF L4

THEOREM L5_Implies_L4 ==
    \A h \in Seq(OpRecord) : L5(h) => L4(h)
PROOF BY DEF L5

THEOREM L6_Implies_L5 ==
    \A h \in Seq(OpRecord) : L6(h) => L5(h)
PROOF BY DEF L6

(* ------------------------------------------------------------------------ *)
(* Transitive soundness theorems                                              *)
(* ------------------------------------------------------------------------ *)

THEOREM L3_PreventsA1 ==
    \A h \in Seq(OpRecord) : L3(h) => ~StaleGeneration(h)
PROOF BY DEF L3, L2

THEOREM L3_PreventsA5 ==
    \A h \in Seq(OpRecord) : L3(h) => ~LongGeneration(h)
PROOF BY DEF L3, L2

THEOREM L4_PreventsA1 ==
    \A h \in Seq(OpRecord) : L4(h) => ~StaleGeneration(h)
PROOF BY DEF L4, L3, L2

THEOREM L4_PreventsA3 ==
    \A h \in Seq(OpRecord) : L4(h) => ~CausalCascade(h)
PROOF BY DEF L4, L3

THEOREM L4_PreventsA5 ==
    \A h \in Seq(OpRecord) : L4(h) => ~LongGeneration(h)
PROOF BY DEF L4, L3, L2

THEOREM L5_PreventsA1 ==
    \A h \in Seq(OpRecord) : L5(h) => ~StaleGeneration(h)
PROOF BY DEF L5, L4, L3, L2

THEOREM L5_PreventsA3 ==
    \A h \in Seq(OpRecord) : L5(h) => ~CausalCascade(h)
PROOF BY DEF L5, L4, L3

THEOREM L5_PreventsA5 ==
    \A h \in Seq(OpRecord) : L5(h) => ~LongGeneration(h)
PROOF BY DEF L5, L4, L3, L2

THEOREM L5_PreventsA6 ==
    \A h \in Seq(OpRecord) : L5(h) => ~ToolEffectReordering(h)
PROOF BY DEF L5, L4

THEOREM L6_PreventsA1 ==
    \A h \in Seq(OpRecord) : L6(h) => ~StaleGeneration(h)
PROOF BY DEF L6, L5, L4, L3, L2

THEOREM L6_PreventsA3 ==
    \A h \in Seq(OpRecord) : L6(h) => ~CausalCascade(h)
PROOF BY DEF L6, L5, L4, L3

THEOREM L6_PreventsA4 ==
    \A h \in Seq(OpRecord) : L6(h) => ~SplitView(h)
PROOF BY DEF L6, L5

THEOREM L6_PreventsA5 ==
    \A h \in Seq(OpRecord) : L6(h) => ~LongGeneration(h)
PROOF BY DEF L6, L5, L4, L3, L2

THEOREM L6_PreventsA6 ==
    \A h \in Seq(OpRecord) : L6(h) => ~ToolEffectReordering(h)
PROOF BY DEF L6, L5, L4

(* ------------------------------------------------------------------------ *)
(* Aggregate hierarchy theorem                                                *)
(* ------------------------------------------------------------------------ *)

THEOREM HierarchyTheorem ==
    \A h \in Seq(OpRecord) :
        /\ L1(h) => L0(h)
        /\ L2(h) => L1(h)
        /\ L3(h) => L2(h)
        /\ L4(h) => L3(h)
        /\ L5(h) => L4(h)
        /\ L6(h) => L5(h)
PROOF BY DEF L0, L1, L2, L3, L4, L5, L6

================================================================================
