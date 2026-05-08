------------------------------- MODULE Hierarchy -------------------------------
EXTENDS Memory, Anomalies, Levels, TLAPS

(* (1) Containment theorems *)

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

(* (2) Direct soundness theorems — explicit conjunction elimination     *)
(* in two steps so Zenon doesn't try to unfold the anomaly definition. *)

THEOREM L2_PreventsA1 ==
    \A h \in Seq(OpRecord) : L2(h) => ~StaleGeneration(h)
PROOF
    <1> SUFFICES ASSUME NEW h \in Seq(OpRecord), L2(h)
                 PROVE  ~StaleGeneration(h)
        OBVIOUS
    <1>1. ~StaleGeneration(h) /\ ~LongGeneration(h)
        BY DEF L2
    <1> QED BY <1>1

THEOREM L2_PreventsA5 ==
    \A h \in Seq(OpRecord) : L2(h) => ~LongGeneration(h)
PROOF
    <1> SUFFICES ASSUME NEW h \in Seq(OpRecord), L2(h)
                 PROVE  ~LongGeneration(h)
        OBVIOUS
    <1>1. ~StaleGeneration(h) /\ ~LongGeneration(h)
        BY DEF L2
    <1> QED BY <1>1

THEOREM L3_PreventsA3 ==
    \A h \in Seq(OpRecord) : L3(h) => ~CausalCascade(h)
PROOF
    <1> SUFFICES ASSUME NEW h \in Seq(OpRecord), L3(h)
                 PROVE  ~CausalCascade(h)
        OBVIOUS
    <1>1. L2(h) /\ ~CausalCascade(h)
        BY DEF L3
    <1> QED BY <1>1

THEOREM L4_PreventsA6 ==
    \A h \in Seq(OpRecord) : L4(h) => ~ToolEffectReordering(h)
PROOF
    <1> SUFFICES ASSUME NEW h \in Seq(OpRecord), L4(h)
                 PROVE  ~ToolEffectReordering(h)
        OBVIOUS
    <1>1. L3(h) /\ ~ToolEffectReordering(h)
        BY DEF L4
    <1> QED BY <1>1

THEOREM L5_PreventsA4 ==
    \A h \in Seq(OpRecord) : L5(h) => ~SplitView(h)
PROOF
    <1> SUFFICES ASSUME NEW h \in Seq(OpRecord), L5(h)
                 PROVE  ~SplitView(h)
        OBVIOUS
    <1>1. L4(h) /\ ~SplitView(h)
        BY DEF L5
    <1> QED BY <1>1

THEOREM L6_PreventsA2 ==
    \A h \in Seq(OpRecord) : L6(h) => ~PhantomTool(h)
PROOF
    <1> SUFFICES ASSUME NEW h \in Seq(OpRecord), L6(h)
                 PROVE  ~PhantomTool(h)
        OBVIOUS
    <1>1. L5(h) /\ ~PhantomTool(h)
        BY DEF L6
    <1> QED BY <1>1

(* (3) Transitive soundness theorems — passed before, keep as-is *)

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

(* Aggregate hierarchy theorem *)

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
