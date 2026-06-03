#!/bin/bash
# =====================================================================
# Artifact alignment for paper v4_6
# =====================================================================
#
# Run this from your mac-consistency repo root, e.g.
#   /home/neo/RustroverProjects/mac-consistency
#
# It will:
#   1. Replace tla/Anomalies.tla   (drops A_5; A_4 vacuous)
#   2. Replace tla/Levels.tla      (5 levels, no L_1 placeholder, no A_5)
#   3. Replace proofs/Hierarchy.tla (11 obligations)
#
# After running, re-verify with:
#   tlapm proofs/Hierarchy.tla
# Expected: 11 obligations proved.
#
# tla/Memory.tla is unchanged from your current state (assuming it has
# OpRecord and LatestWriteBefore). If it does not, see the v4_5 artifact
# bundle for the Memory.tla file.
#
# Optional cleanup of v5-specific files (not needed for v4_6 verification):
#   rm -f proofs/Mechanisms.tla
#   rm -f proofs/A1LowerBound.tla
#   rm -f proofs/Incomparability.tla
#   rm -f proofs/Streaming.tla
#   rm -f proofs/CompletenessProof.tla
#   rm -f proofs/Refinement.tla
#   rm -f tla/MC_L3a_NotL3b.tla tla/MC_L3a_NotL3b.cfg
#   rm -f tla/MC_L3b_NotL3a.tla tla/MC_L3b_NotL3a.cfg
# Also optional: drop the A_5 TLC harness if present
#   rm -f tla/MC_A5_witness.tla tla/MC_A5_witness.cfg
# =====================================================================

set -e

if [ ! -d "tla" ] || [ ! -d "proofs" ]; then
  echo "ERROR: must be run from the mac-consistency repo root"
  echo "       (expected ./tla and ./proofs directories)"
  exit 1
fi

# Backup existing files first
mkdir -p .backup_v4_5
cp -f tla/Anomalies.tla    .backup_v4_5/Anomalies.tla    2>/dev/null || true
cp -f tla/Levels.tla       .backup_v4_5/Levels.tla       2>/dev/null || true
cp -f proofs/Hierarchy.tla .backup_v4_5/Hierarchy.tla    2>/dev/null || true
echo "Existing files backed up to .backup_v4_5/"

# ---------------------------------------------------------------------
# 1. tla/Anomalies.tla
# ---------------------------------------------------------------------
cat > tla/Anomalies.tla << 'EOF_ANOMALIES'
---------------------------- MODULE Anomalies ----------------------------
(***************************************************************************
  Anomalies.tla — paper v4_6 alignment.

  Four formalised concurrency anomaly predicates over operation histories:
    A_1  StaleGeneration         — intervening write invalidates a read
    A_2  PhantomTool              — registry mutation removes planned tool
    A_3  CausalCascade            — basis of an external commit retracted
    A_6  ToolEffectReordering     — co != io within a single operation

  A_4 (SplitView) is vacuous in the present model and kept as a
  constant FALSE for syntactic completeness.

  Removed in v4_6: A_5 (LongGeneration). The paper v4_6 acknowledges
  multi-intervening writes as a special case of A_1, with bounded-staleness
  refinements cited via Bailis et al. 2012 (PBS). The A_5 predicate is
  no longer used by any level.
 ***************************************************************************)
EXTENDS Naturals, Sequences, Memory

------------------------------------------------------------------------
(* A_1: StaleGeneration                                                 *)
------------------------------------------------------------------------
StaleGeneration(h) ==
    \E i, j \in 1..Len(h) :
        /\ i # j
        /\ h[i].agent # h[j].agent
        /\ \E c \in h[i].read_set \cap h[j].write_set :
            /\ h[i].read_time  < h[j].write_time
            /\ h[j].write_time < h[i].write_time
            /\ h[i].read_values[c] # h[j].write_values[c]

------------------------------------------------------------------------
(* A_2: PhantomTool                                                     *)
------------------------------------------------------------------------
PhantomTool(h) ==
    \E i \in 1..Len(h) :
        /\ h[i].planned_tool # NULL
        /\ h[i].planned_tool \in h[i].read_registry
        /\ h[i].planned_tool \notin h[i].write_registry

------------------------------------------------------------------------
(* A_3: CausalCascade                                                   *)
------------------------------------------------------------------------
CausalCascade(h) ==
    \E j \in 1..Len(h) :
        /\ h[j].write_set \cap ExternalCells # {}
        /\ \E c \in h[j].read_set, k \in 1..Len(h) :
            /\ c \notin ExternalCells
            /\ k # j
            /\ c \in h[k].write_set
            /\ h[k].write_time > h[j].write_time
            /\ h[k].write_values[c] # h[j].read_values[c]

------------------------------------------------------------------------
(* A_4: SplitView                                                       *)
(* Vacuous in the present model (no replication).                      *)
------------------------------------------------------------------------
SplitView(h) == FALSE

------------------------------------------------------------------------
(* A_6: ToolEffectReordering                                            *)
------------------------------------------------------------------------
ToolEffectReordering(h) ==
    \E i \in 1..Len(h) :
        /\ Len(h[i].io) >= 2
        /\ h[i].co # h[i].io
        /\ IsPermutation(h[i].io, h[i].co)

------------------------------------------------------------------------
(* Negation predicates used by Levels.tla                               *)
------------------------------------------------------------------------
StaleGenerationFree(h)         == ~StaleGeneration(h)
PhantomToolFree(h)             == ~PhantomTool(h)
CausalCascadeFree(h)           == ~CausalCascade(h)
SplitViewFree(h)               == ~SplitView(h)
ToolEffectReorderingFree(h)    == ~ToolEffectReordering(h)

==========================================================================
EOF_ANOMALIES
echo "  written: tla/Anomalies.tla"

# ---------------------------------------------------------------------
# 2. tla/Levels.tla
# ---------------------------------------------------------------------
cat > tla/Levels.tla << 'EOF_LEVELS'
---------------------------- MODULE Levels ----------------------------
(***************************************************************************
  Levels.tla — paper v4_6 alignment.

  Five consistency levels L_0 .. L_4 forming a linear hierarchy under
  entailment. Renumbered from v4_5 (which had L_0..L_6 with redundancies):

    Old L_0 (TRUE)            -> dropped (subsumed by new L_0)
    Old L_1 (TRUE placeholder) -> dropped
    Old L_2 (~A_1 /\ ~A_5)    -> new L_1 (just ~A_1; A_5 redundant)
    Old L_3 (L_2 /\ ~A_3)     -> new L_2
    Old L_4 (L_3 /\ ~A_6)     -> new L_3 (absorbs old L_5, since A_4 vacuous)
    Old L_5 (L_4 /\ ~A_4)     -> dropped (A_4 vacuous in present model)
    Old L_6 (L_5 /\ ~A_2)     -> new L_4

  L_2 and L_3 are noted as incomparable in the paper §4.2 (the
  presentation is one of two equivalent linear extensions).
 ***************************************************************************)
EXTENDS Naturals, Sequences, Memory, Anomalies

L0(h) == TRUE

L1(h) == StaleGenerationFree(h)

L2(h) == /\ L1(h)
         /\ CausalCascadeFree(h)

L3(h) == /\ L2(h)
         /\ ToolEffectReorderingFree(h)

L4(h) == /\ L3(h)
         /\ PhantomToolFree(h)

==========================================================================
EOF_LEVELS
echo "  written: tla/Levels.tla"

# ---------------------------------------------------------------------
# 3. proofs/Hierarchy.tla
# ---------------------------------------------------------------------
cat > proofs/Hierarchy.tla << 'EOF_HIERARCHY'
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
EOF_HIERARCHY
echo "  written: proofs/Hierarchy.tla"

echo ""
echo "==============================================="
echo "Artifact aligned to paper v4_6."
echo ""
echo "Verify with:"
echo "  tlapm proofs/Hierarchy.tla"
echo ""
echo "Expected: 11 obligations proved."
echo "==============================================="