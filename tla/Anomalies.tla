---------------------------- MODULE Anomalies ----------------------------
(***************************************************************************
  Anomalies.tla — paper v5_3 alignment.

  Four formalised concurrency anomaly predicates over operation histories:
    A_1  StaleGeneration         — intervening write invalidates a read
    A_2  PhantomTool              — registry mutation removes planned tool
    A_3  CausalCascade            — surviving op retains an ABORTED
                                    predecessor in its causal closure
                                    (precise cascade-abort predicate;
                                     paper Definition 3, Sec. 3.3)
    A_6  ToolEffectReordering     — co != io within a single operation

  A_4 (SplitView) is vacuous in the present model and kept as a
  constant FALSE for syntactic completeness; its formalization lives in
  the Verus development (lib_a4_split_view.rs).

  Removed in v4_6: A_5 (LongGeneration). The paper acknowledges
  multi-intervening writes as a special case of A_1, with bounded-staleness
  refinements cited via Bailis et al. 2012 (PBS). The A_5 predicate is
  no longer used by any level.

  A_3 redefinition (paper Sec. 3.3, "Option A"): earlier versions defined
  CausalCascade as the flat-history residue — a committed read of a value
  no surviving committed write produced at or before the read. That residue
  is a SOUND OVER-APPROXIMATION of the cascade but not its characteristic
  predicate: it also fires, benignly, on a read of an initial, seeded, or
  externally-supplied value that no logged operation wrote, even in an
  execution with no abort — so no runtime could prevent it. The cataloged
  CausalCascade below is now the precise cascade-abort condition (the trace
  image of lib_l2_safety.rs::a3_witness, which Theorem L2h proves absent
  on every reachable L2 state), and the residue is RETAINED separately as
  CausalCascadeResidue: it is the predicate the verified flat-trace Verus
  detector (detect_a3, lib_detector_equivalence.rs) is proved sound and
  complete against, for black-box traces that expose neither preds nor
  aborted. CausalCascade(h) => CausalCascadeResidue(proj(h)) on the
  projected flat history; the converse fails on un-logged initial values.
  The TLC discrimination check for the redefinition is A3_witness_check.tla
  (cascade fires; benign serial silent; residue fires on benign).
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
(* A_3: CausalCascade — the cataloged predicate (paper Definition 3).   *)
(*                                                                      *)
(* Trace image of lib_l2_safety.rs::a3_witness: a SURVIVING (committed, *)
(* non-aborted) operation retains in its causal closure a predecessor   *)
(* that was ABORTED — its basis was retracted and it was not itself     *)
(* compensated. Records carry an `aborted` flag and a `preds` set (the  *)
(* causal closure at read time, the writer's own preds unioned in; see  *)
(* the L2 model). Theorem L2h (lemma_l2_reachable_no_a3) proves no      *)
(* reachable L2 state satisfies it; Theorem L2g shows it is satisfiable.*)
------------------------------------------------------------------------
CausalCascade(h) ==
    \E j \in 1..Len(h), p \in 1..Len(h) :
        /\ ~ h[j].aborted
        /\ p \in h[j].preds
        /\ h[p].aborted

------------------------------------------------------------------------
(* A_3 residue: CausalCascadeResidue — the flat-trace detector predicate*)
(*                                                                      *)
(* A committed read of c = v (v # NULL) that no surviving committed     *)
(* write produced at or before that read. Sound over-approximation of   *)
(* the cascade for black-box traces that expose neither preds nor       *)
(* aborted: every genuine cascade with a surviving committed reader     *)
(* leaves a residue witness; the residue additionally fires on reads of *)
(* un-logged initial values (the over-approximation the redefinition    *)
(* removes from the cataloged predicate). This is the predicate the     *)
(* verified Verus detector detect_a3 is proved sound and complete       *)
(* against (lib_detector_equivalence.rs).                               *)
------------------------------------------------------------------------
CausalCascadeResidue(h) ==
    \E j \in 1..Len(h) :
        \E c \in h[j].read_set :
            /\ h[j].read_values[c] # NULL
            /\ \A k \in 1..Len(h) :
                  ~( /\ k # j
                     /\ c \in h[k].write_set
                     /\ h[k].write_time =< h[j].read_time
                     /\ h[k].write_values[c] = h[j].read_values[c] )

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
CausalCascadeResidueFree(h)    == ~CausalCascadeResidue(h)
SplitViewFree(h)               == ~SplitView(h)
ToolEffectReorderingFree(h)    == ~ToolEffectReordering(h)

==========================================================================
