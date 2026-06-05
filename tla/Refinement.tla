--------------------------- MODULE Refinement ---------------------------
(***************************************************************************)
(* Refinement theorem: CodeCRDT.Spec implements Memory.Spec under the    *)
(* projection phi defined in CodeCRDT.tla.                               *)
(*                                                                         *)
(* STATUS: WORK IN PROGRESS -- this module does NOT check. The action     *)
(* refinement steps are OMITTED skeletons (see note at end); the aggregate*)
(* theorem is a placeholder. It is supplementary scaffolding only and is  *)
(* not cited as a verified result: CodeCRDT's level placement (Thm 6.1)   *)
(* is established by the TLC harnesses MC_CodeCRDT_RYW (LostSelfWrite     *)
(* vacuity) and MC_CodeCRDT_AdmitsA1 (StaleGeneration violation), not by  *)
(* this file. Excluded from the verified-artifact proof set.              *)
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
(*      GlobalMemory under phi, which is FALSE in general -- this is     *)
(*      why CodeCRDT is at L_1, not L_2: it admits StaleGeneration and    *)
(*      so the refinement is NOT to the strong Memory.Spec but to a      *)
(*      weakened spec where the read action can return any past memory    *)
(*      value. The MemoryProjection instance in CodeCRDT.tla sets         *)
(*      AllowSkew <- TRUE precisely to be that weakened, staleness-        *)
(*      permitting target.)                                               *)
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
(*   CodeCRDT.Spec => Memory.Spec  (with AllowSkew = TRUE, staleness-     *)
(*   permitting). This is the honest level placement of CodeCRDT: it      *)
(* refines a relaxed Memory operationally and admits A_1 against the      *)
(* strong (grounded, AllowSkew = FALSE) Memory.                          *)
(*                                                                         *)
(* Mechanisation proceeds by:                                             *)
(*   1. The staleness-permitting target is Memory with AllowSkew <- TRUE  *)
(*      (already wired in CodeCRDT.tla's MemoryProjection instance).      *)
(*   2. Showing the simulation: every CodeCRDT step is matched by a      *)
(*      MemoryProjection step (or stuttering) under phi.                  *)
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
    \* inflight, registry, GlobalMemory all unchanged. GlobalMemory is a
    \* function of log alone, so log' = log gives GlobalMemory' =
    \* GlobalMemory by congruence -- no need to unfold the RECURSIVE
    \* ApplyForward (and unfolding it here crashes tlapm normalisation).
    BY DEF SyncReplica, phiLog, phiInflight, phiRegistry, phiMemory,
           GlobalMemory

\* Note on StartRead: CodeCRDT's StartRead populates read_values from
\* Replica(a), which equals ApplyForward(InitialMemory, 1, syncClock[a])
\* -- a (possibly stale) prefix of the log. Memory's StartRead populates
\* read_values from `memory`, which is the full log's projection. These
\* coincide ONLY when syncClock[a] = Len(log). In general they differ,
\* which is why CodeCRDT does NOT refine the strong (AllowSkew = FALSE)
\* Memory.Spec; it refines the relaxed (AllowSkew = TRUE) target.
\*
\* The honest theorem is therefore:
\*   CodeCRDT.Spec => MemoryProjection!Spec  (AllowSkew = TRUE: refinement)
\*   CodeCRDT.Spec =/=> Memory.Spec          (AllowSkew = FALSE: does not refine)
\*
\* This is the formal expression of "CodeCRDT is at L_1 but not L_2."

\* Aggregate refinement theorem (against the relaxed target).
THEOREM CodeCRDT_Refines_RelaxedMemory ==
    Spec => MemoryProjection!Spec
PROOF
    OMITTED  \* See sketch above; ~200 LoC TLAPS effort.

==========================================================================
