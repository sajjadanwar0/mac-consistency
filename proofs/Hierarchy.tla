---------------------------- MODULE Hierarchy ----------------------------
(***************************************************************************
  Hierarchy.tla — paper v4_6 alignment.

  Mechanical coherence check on the level definitions of Levels.tla.
  Eleven obligations, all dispatched by definitional unfolding.

  Obligation breakdown:
    - 4 adjacent-pair containments  (L_{i+1} => L_i for i in {0,1,2,3})
    - 6 transitive soundness         (L_k => ~A_j for k > first-negation level)
    - 1 aggregate hierarchy theorem
    Total: 11

  Anomalies and their first-negation level:
    A_1 (StaleGeneration)        first negated at L_1
    A_3 (CausalCascade)          first negated at L_2
    A_6 (ToolEffectReordering)   first negated at L_3
    A_2 (PhantomTool)            first negated at L_4

  Transitive obligations (k > first-negation level):
    ~A_1 at L_2, L_3, L_4    (3)
    ~A_3 at L_3, L_4         (2)
    ~A_6 at L_4              (1)
    ~A_2 at (none above L_4) (0)
    Total transitive:        6
 ***************************************************************************)
EXTENDS Naturals, Sequences, Memory, Anomalies, Levels

------------------------------------------------------------------------
(* SECTION 1: Four adjacent-pair containment theorems                   *)
------------------------------------------------------------------------

THEOREM L1_Implies_L0 ==
    \A h \in Seq(OpRecord) : L1(h) => L0(h)
  PROOF BY DEF L0, L1

THEOREM L2_Implies_L1 ==
    \A h \in Seq(OpRecord) : L2(h) => L1(h)
  PROOF BY DEF L1, L2

THEOREM L3_Implies_L2 ==
    \A h \in Seq(OpRecord) : L3(h) => L2(h)
  PROOF BY DEF L2, L3

THEOREM L4_Implies_L3 ==
    \A h \in Seq(OpRecord) : L4(h) => L3(h)
  PROOF BY DEF L3, L4

------------------------------------------------------------------------
(* SECTION 2: Six transitive soundness theorems                         *)
------------------------------------------------------------------------

\* L_2 prevents A_1
THEOREM L2_PreventsA1 ==
    \A h \in Seq(OpRecord) : L2(h) => StaleGenerationFree(h)
  PROOF BY DEF L2, L1

\* L_3 prevents A_1, A_3
THEOREM L3_PreventsA1 ==
    \A h \in Seq(OpRecord) : L3(h) => StaleGenerationFree(h)
  PROOF BY DEF L3, L2, L1

THEOREM L3_PreventsA3 ==
    \A h \in Seq(OpRecord) : L3(h) => CausalCascadeFree(h)
  PROOF BY DEF L3, L2

\* L_4 prevents A_1, A_3, A_6
THEOREM L4_PreventsA1 ==
    \A h \in Seq(OpRecord) : L4(h) => StaleGenerationFree(h)
  PROOF BY DEF L4, L3, L2, L1

THEOREM L4_PreventsA3 ==
    \A h \in Seq(OpRecord) : L4(h) => CausalCascadeFree(h)
  PROOF BY DEF L4, L3, L2

THEOREM L4_PreventsA6 ==
    \A h \in Seq(OpRecord) : L4(h) => ToolEffectReorderingFree(h)
  PROOF BY DEF L4, L3

------------------------------------------------------------------------
(* SECTION 3: Aggregate hierarchy theorem                               *)
------------------------------------------------------------------------

THEOREM Hierarchy ==
    \A h \in Seq(OpRecord) :
        /\ L1(h) => L0(h)
        /\ L2(h) => L1(h)
        /\ L3(h) => L2(h)
        /\ L4(h) => L3(h)
  PROOF BY L1_Implies_L0, L2_Implies_L1, L3_Implies_L2, L4_Implies_L3

------------------------------------------------------------------------
(* Total: 4 (adjacent) + 6 (transitive) + 1 (aggregate) = 11 obligations *)
(* All dispatched by definitional unfolding.                             *)
------------------------------------------------------------------------

==========================================================================
