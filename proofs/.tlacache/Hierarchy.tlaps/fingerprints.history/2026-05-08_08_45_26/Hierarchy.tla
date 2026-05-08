------------------------------- MODULE Hierarchy -------------------------------
(***************************************************************************)
(* Mechanically verified hierarchy theorems for the consistency levels    *)
(* L0 through L6 over the anomaly catalogue {A1, A2, A3, A4, A5, A6}.    *)
(*                                                                          *)
(* The proofs proceed in three groups:                                    *)
(*                                                                          *)
(*   (1) Containment: L_{i+1}(h) => L_i(h) for all adjacent levels.       *)
(*   (2) Direct soundness: each level prevents its definitionally-named   *)
(*       anomaly by conjunction elimination over the level definition.   *)
(*   (3) Transitive soundness: stronger levels prevent the anomalies     *)
(*       prevented by all weaker levels, by chaining (1) and (2).        *)
(*                                                                          *)
(* All proofs are short — the level definitions in Levels.tla make the   *)
(* prevention relations true by construction.                            *)
(***************************************************************************)

EXTENDS Memory, Anomalies, Levels, TLAPS

(* ------------------------------------------------------------------------ *)
(* (1) Containment theorems                                                  *)
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
(* (2) Direct soundness theorems                                             *)
(* ------------------------------------------------------------------------ *)

THEOREM L2_PreventsA1 ==
    \A h \in Seq(OpRecord) : L2(h) => ~StaleGeneration(h)
PROOF BY DEF L2

THEOREM L2_PreventsA5 ==
    \A h \in Seq(OpRecord) : L2(h) => ~LongGeneration(h)
PROOF BY DEF L2

THEOREM L3_PreventsA3 ==
    \A h \in Seq(OpRecord) : L3(h) => ~CausalCascade(h)
PROOF BY DEF L3

THEOREM L4_PreventsA6 ==
    \A h \in Seq(OpRecord) : L4(h) => ~ToolEffectReordering(h)
PROOF BY DEF L4

THEOREM L5_PreventsA4 ==
    \A h \in Seq(OpRecord) : L5(h) => ~SplitView(h)
PROOF BY DEF L5

THEOREM L6_PreventsA2 ==
    \A h \in Seq(OpRecord) : L6(h) => ~PhantomTool(h)
PROOF BY DEF L6

(* ------------------------------------------------------------------------ *)
(* (3) Transitive soundness theorems                                         *)
(* ------------------------------------------------------------------------ *)

(* L3 inherits L2's preventions. *)

THEOREM L3_PreventsA1 ==
    \A h \in Seq(OpRecord) : L3(h) => ~StaleGeneration(h)
PROOF BY DEF L3, L2

THEOREM L3_PreventsA5 ==
    \A h \in Seq(OpRecord) : L3(h) => ~LongGeneration(h)
PROOF BY DEF L3, L2

(* L4 inherits L3's preventions. *)

THEOREM L4_PreventsA1 ==
    \A h \in Seq(OpRecord) : L4(h) => ~StaleGeneration(h)
PROOF BY DEF L4, L3, L2

THEOREM L4_PreventsA3 ==
    \A h \in Seq(OpRecord) : L4(h) => ~CausalCascade(h)
PROOF BY DEF L4, L3

THEOREM L4_PreventsA5 ==
    \A h \in Seq(OpRecord) : L4(h) => ~LongGeneration(h)
PROOF BY DEF L4, L3, L2

(* L5 inherits L4's preventions. *)

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

(* L6 inherits L5's preventions. *)

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
(* Aggregate hierarchy theorem                                              *)
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
