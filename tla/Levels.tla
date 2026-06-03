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
