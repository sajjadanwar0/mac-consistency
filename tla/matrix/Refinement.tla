--------------------------- MODULE Refinement ---------------------------
(***************************************************************************)
(* Refinement theorem: CodeCRDT.Spec implements Memory.Spec under the    *)
(* projection phi defined in CodeCRDT.tla.                               *)
(*                                                                         *)
(* STATEMENT.                                                              *)
(*   THEOREM CodeCRDT_Refines_Memory ==                                   *)
(*     CodeCRDT!Spec => CodeCRDT!MemoryProjection!Spec                    *)
(*                                                                         *)
(* The proof is by stuttering-respecting simulation. CodeCRDT's three    *)
(* actions map to Memory's actions as follows:                            *)
(*                                                                         *)
(*   StartRead(a)         in CodeCRDT  ->  StartRead(a) in Memory         *)
(*     (Replica(a) projected to GlobalMemory before phi; refinement      *)
(*      requires showing that CodeCRDT's read_values are dominated by     *)
(*      GlobalMemory under phi, which is FALSE in general — this is      *)
(*      why CodeCRDT is at L_1, not L_2: it admits StaleGeneration and    *)
(*      so the refinement is NOT to the strong Memory.Spec but to a      *)
(*      weakened spec MemoryWithStaleness.Spec where the read action      *)
(*      can return any past memory value.)                                *)
(*                                                                         *)
(*   CompleteWrite(a)     in CodeCRDT  ->  CompleteWrite(a) in Memory     *)
(*     (Direct correspondence; both append the same record.)              *)
(*                                                                         *)
(*   SyncReplica(a)       in CodeCRDT  ->  stuttering step in Memory      *)
(*     (No memory mutation; phi-image unchanged.)                          *)
(*                                                                         *)
(*   RemoveTool(t)        in CodeCRDT  ->  RemoveTool(t) in Memory        *)
(*     (Direct correspondence.)                                            *)
(*                                                                         *)
(* The refinement direction is therefore:                                 *)
(*   CodeCRDT.Spec => MemoryWithStaleness.Spec                           *)
(* where MemoryWithStaleness is Memory with StartRead's read_values       *)
(* drawn from any past memory state, not the current one. This is the     *)
(* honest level placement of CodeCRDT: it refines a relaxed Memory       *)
(* operationally and admits A_1 against the strong Memory.                *)
(*                                                                         *)
(* The refinement to MemoryWithStaleness is a real theorem (not a        *)
(* tautology). Mechanisation proceeds by:                                 *)
(*   1. Defining MemoryWithStaleness.tla with a relaxed StartRead.       *)
(*   2. Showing the simulation: every CodeCRDT step is matched by a      *)
(*      MemoryWithStaleness step (or stuttering) under phi.               *)
(*   3. Inducting on action types.                                       *)
(*                                                                         *)
(* This is non-trivial work (~200 LoC TLAPS, multi-day effort). The      *)
(* skeleton below records the structure; the OMITTED steps are where     *)
(* the inductive case work goes.                                          *)
(***************************************************************************)

EXTENDS CodeCRDT, TLAPS

\* The state variables of CodeCRDT mapped through phi.
phiVars == <<phiLog, phiInflight, phiRegistry, phiMemory>>

\* Init refinement: CodeCRDT's Init implies Memory's Init under phi.
THEOREM Init_Refines ==
    Init => MemoryProjection!Init
PROOF
    \* CodeCRDT.Init: log = <<>>, inflight = empty, syncClock = 0, registry = Tools.
    \* phi-image: log = <<>>, inflight = empty, registry = Tools, memory = InitialMemory.
    \* Memory.Init requires log = <<>>, inflight = empty, registry = Tools, memory = InitialMemory.
    \* The phi-image matches: GlobalMemory at log = <<>> is InitialMemory.
    OMITTED  \* Discharge by unfolding ApplyForward at empty log.

\* Action refinement, per action.
THEOREM CompleteWrite_Refines ==
    \A a \in Agents :
        CompleteWrite(a) /\ vars' = phiVars'
        => MemoryProjection!CompleteWrite(a)
PROOF
    \* CodeCRDT's CompleteWrite appends to log AND advances syncClock[a].
    \* Memory's CompleteWrite appends to log AND updates memory.
    \* Under phi, advancing syncClock[a] is invisible (only the global
    \* log shape matters for GlobalMemory). The new GlobalMemory is the
    \* old GlobalMemory updated at the new write_set, which matches
    \* Memory's memory update.
    OMITTED  \* Inductive case work.

THEOREM SyncReplica_Stutters ==
    \A a \in Agents :
        SyncReplica(a) => UNCHANGED phiVars
PROOF
    \* SyncReplica only updates syncClock, which phi discards. log,
    \* inflight, registry, GlobalMemory all unchanged.
    BY DEF SyncReplica, phiLog, phiInflight, phiRegistry, phiMemory,
           GlobalMemory, ApplyForward

\* Note on StartRead: CodeCRDT's StartRead populates read_values from
\* Replica(a), which equals ApplyForward(InitialMemory, 1, syncClock[a])
\* — a (possibly stale) prefix of the log. Memory's StartRead populates
\* read_values from `memory`, which is the full log's projection. These
\* coincide ONLY when syncClock[a] = Len(log). In general they differ,
\* which is why CodeCRDT does NOT refine the strong Memory.Spec; it
\* refines a relaxed MemoryWithStaleness.Spec.
\*
\* The honest theorem is therefore:
\*   CodeCRDT.Spec => MemoryWithStaleness.Spec   (refinement)
\*   CodeCRDT.Spec =/=> Memory.Spec                (does not refine strong)
\*
\* This is the formal expression of "CodeCRDT is at L_1 but not L_2."

\* Aggregate refinement theorem (against the relaxed spec).
\* Requires defining MemoryWithStaleness.tla as a sibling module.
THEOREM CodeCRDT_Refines_RelaxedMemory ==
    Spec => phiVars  \* placeholder: MemoryWithStaleness!Spec under phi
PROOF
    OMITTED  \* See sketch above; ~200 LoC TLAPS effort.

==========================================================================
