------------------------------- MODULE Hierarchy -------------------------------
(***************************************************************************)
(* Mechanically verified hierarchy theorems for the consistency levels    *)
(* L_0, L_1, L_2, L_3a, L_3b, L_4, L_5, L_6 over the anomaly catalogue.  *)
(*                                                                         *)
(* OBLIGATION COUNT (21 total):                                           *)
(*   8 cover-relation containments                                        *)
(*  12 transitive-soundness theorems for non-vacuous anomalies            *)
(*   1 aggregate hierarchy theorem                                        *)
(*                                                                         *)
(* SCOPE NOTE.                                                             *)
(* The "direct" soundness claims — that L_i prevents the anomaly added   *)
(* at level i — are tautologies of the level definitions in Levels.tla.  *)
(* For instance, L_2(h) is defined as L_1(h) /\ ~StaleGeneration(h), so  *)
(* L_2(h) => ~StaleGeneration(h) holds by /\-elimination. We do not      *)
(* state these as separate TLAPS theorems; the paper cites them by       *)
(* inspection of the definitions.                                         *)
(*                                                                         *)
(* The "transitive" soundness theorems below — that stronger levels      *)
(* prevent anomalies prevented by all weaker ancestor levels — are       *)
(* coherence checks discharged by definitional unfolding. They are NOT   *)
(* deep results; the paper's coherence theorem is a definitional sanity  *)
(* check, not a non-trivial verification claim.                           *)
(*                                                                         *)
(* Transitive theorems for A_0 are omitted because A_0 is vacuously       *)
(* prevented in M (SplitView is FALSE, LostSelfWrite cannot fire because  *)
(* memory always reflects the latest log entry). The paper §3.1 states   *)
(* this explicitly.                                                       *)
(***************************************************************************)

EXTENDS Memory, Anomalies, Levels, TLAPS

(* ------------------------------------------------------------------------ *)
(* Containment theorems: 8 cover relations in the partial order.           *)
(* ------------------------------------------------------------------------ *)

THEOREM L1_Implies_L0 ==
    \A h \in Seq(OpRecord) : L1(h) => L0(h)
PROOF BY DEF L0, L1

THEOREM L2_Implies_L1 ==
    \A h \in Seq(OpRecord) : L2(h) => L1(h)
PROOF BY DEF L2

THEOREM L3a_Implies_L2 ==
    \A h \in Seq(OpRecord) : L3a(h) => L2(h)
PROOF BY DEF L3a

THEOREM L3b_Implies_L2 ==
    \A h \in Seq(OpRecord) : L3b(h) => L2(h)
PROOF BY DEF L3b

THEOREM L4_Implies_L3a ==
    \A h \in Seq(OpRecord) : L4(h) => L3a(h)
PROOF BY DEF L4

THEOREM L4_Implies_L3b ==
    \A h \in Seq(OpRecord) : L4(h) => L3b(h)
PROOF BY DEF L4

THEOREM L5_Implies_L4 ==
    \A h \in Seq(OpRecord) : L5(h) => L4(h)
PROOF BY DEF L5

THEOREM L6_Implies_L5 ==
    \A h \in Seq(OpRecord) : L6(h) => L5(h)
PROOF BY DEF L6

(* ------------------------------------------------------------------------ *)
(* Transitive soundness theorems: 12 for non-vacuous anomalies.            *)
(* A_0 omitted (vacuously prevented in M).                                 *)
(* ------------------------------------------------------------------------ *)

\* A_1 (StaleGeneration) prevented at L_2 onwards.
THEOREM L3a_PreventsA1 ==
    \A h \in Seq(OpRecord) : L3a(h) => ~StaleGeneration(h)
PROOF BY DEF L3a, L2

THEOREM L3b_PreventsA1 ==
    \A h \in Seq(OpRecord) : L3b(h) => ~StaleGeneration(h)
PROOF BY DEF L3b, L2

THEOREM L4_PreventsA1 ==
    \A h \in Seq(OpRecord) : L4(h) => ~StaleGeneration(h)
PROOF BY DEF L4, L3a, L2

THEOREM L5_PreventsA1 ==
    \A h \in Seq(OpRecord) : L5(h) => ~StaleGeneration(h)
PROOF BY DEF L5, L4, L3a, L2

THEOREM L6_PreventsA1 ==
    \A h \in Seq(OpRecord) : L6(h) => ~StaleGeneration(h)
PROOF BY DEF L6, L5, L4, L3a, L2

\* A_3 (CausalCascade) prevented at L_3a, L_4, L_5, L_6 (transitive only).
THEOREM L4_PreventsA3 ==
    \A h \in Seq(OpRecord) : L4(h) => ~CausalCascade(h)
PROOF BY DEF L4, L3a

THEOREM L5_PreventsA3 ==
    \A h \in Seq(OpRecord) : L5(h) => ~CausalCascade(h)
PROOF BY DEF L5, L4, L3a

THEOREM L6_PreventsA3 ==
    \A h \in Seq(OpRecord) : L6(h) => ~CausalCascade(h)
PROOF BY DEF L6, L5, L4, L3a

\* A_6 (ToolEffectReordering) prevented at L_3b, L_4, L_5, L_6 (transitive).
THEOREM L4_PreventsA6 ==
    \A h \in Seq(OpRecord) : L4(h) => ~ToolEffectReordering(h)
PROOF BY DEF L4, L3b

THEOREM L5_PreventsA6 ==
    \A h \in Seq(OpRecord) : L5(h) => ~ToolEffectReordering(h)
PROOF BY DEF L5, L4, L3b

THEOREM L6_PreventsA6 ==
    \A h \in Seq(OpRecord) : L6(h) => ~ToolEffectReordering(h)
PROOF BY DEF L6, L5, L4, L3b

\* A_4 (SplitView) prevented at L_5, L_6. Vacuous in M (SplitView FALSE)
\* but stated for the replication-aware extension.
THEOREM L6_PreventsA4 ==
    \A h \in Seq(OpRecord) : L6(h) => ~SplitView(h)
PROOF BY DEF L6, L5

(* ------------------------------------------------------------------------ *)
(* Aggregate hierarchy theorem: the partial order's cover relations.       *)
(* ------------------------------------------------------------------------ *)

THEOREM HierarchyTheorem ==
    \A h \in Seq(OpRecord) :
        /\ L1(h)  => L0(h)
        /\ L2(h)  => L1(h)
        /\ L3a(h) => L2(h)
        /\ L3b(h) => L2(h)
        /\ L4(h)  => L3a(h)
        /\ L4(h)  => L3b(h)
        /\ L5(h)  => L4(h)
        /\ L6(h)  => L5(h)
PROOF BY DEF L0, L1, L2, L3a, L3b, L4, L5, L6

================================================================================
