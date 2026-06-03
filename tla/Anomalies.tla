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
