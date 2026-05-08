--------------------------------- MODULE Levels --------------------------------
(***************************************************************************)
(* The seven consistency levels L0 through L6.                             *)
(*                                                                          *)
(* Each level is defined by the set of anomalies it prevents — following  *)
(* Berenson et al. (1995) and Adya (1999), where database isolation       *)
(* levels are characterised by the anomalies they prevent rather than by  *)
(* one canonical implementation strategy.                                  *)
(*                                                                          *)
(* Hierarchy (each prevents anomalies prevented by all weaker levels):     *)
(*   L0 — Eventually Visible       (no anomalies prevented)                *)
(*   L1 — Per-Agent RYW            (no listed anomalies prevented)         *)
(*   L2 — Generation Snapshot      (~A1, ~A5)                              *)
(*   L3 — Causal-LLM               (L2 ∧ ~A3)                              *)
(*   L4 — Tool-Atomic              (L3 ∧ ~A6)                              *)
(*   L5 — Agent-Snapshot           (L4 ∧ ~A4)  — same as L4 until A4 modeled *)
(*   L6 — Agent-Serialisable       (L5 ∧ ~A2)                              *)
(*                                                                          *)
(* A note on L2: an alternative formulation defines L2 structurally — as  *)
(* "read_values reflect memory at read_time". That structural property    *)
(* alone does NOT prevent A1 or A5 (lost-update-style anomalies persist  *)
(* under snapshot isolation; this is the classic write-skew result of     *)
(* Berenson et al.). To make L2 prevent A1 and A5 we add their negations *)
(* explicitly. The matrix harness empirically verifies this.              *)
(***************************************************************************)

EXTENDS Memory, Anomalies

L0(history) == TRUE

(* L1. Per-Agent RYW. In our current anomaly catalogue, L1 does not       *)
(* prevent any anomaly. Kept distinct from L0 for completeness; will      *)
(* differ from L0 once an anomaly involving cross-agent self-write        *)
(* visibility is added. *)
L1(history) == TRUE

(* L2. Generation Snapshot, with read-set stability. *)
L2(history) ==
    /\ ~StaleGeneration(history)
    /\ ~LongGeneration(history)

(* L3. Causal-LLM. *)
L3(history) == L2(history) /\ ~CausalCascade(history)

(* L4. Tool-Atomic. *)
L4(history) == L3(history) /\ ~ToolEffectReordering(history)

(* L5. Agent-Snapshot. Currently equivalent to L4 because A4 is FALSE.    *)
(* The distinction becomes meaningful when replication is added.          *)
L5(history) == L4(history) /\ ~SplitView(history)

(* L6. Agent-Serialisable. *)
L6(history) == L5(history) /\ ~PhantomTool(history)

(***************************************************************************)
(* Hierarchy soundness theorems — all true by construction.                *)
(***************************************************************************)

L2_PreventsA1 ==
    \A history \in Seq(OpRecord) : L2(history) => ~StaleGeneration(history)

L2_PreventsA5 ==
    \A history \in Seq(OpRecord) : L2(history) => ~LongGeneration(history)

L3_PreventsA3 ==
    \A history \in Seq(OpRecord) : L3(history) => ~CausalCascade(history)

L4_PreventsA6 ==
    \A history \in Seq(OpRecord) : L4(history) => ~ToolEffectReordering(history)

L6_PreventsA2 ==
    \A history \in Seq(OpRecord) : L6(history) => ~PhantomTool(history)

HierarchyContainment ==
    \A history \in Seq(OpRecord) :
        /\ L1(history) => L0(history)
        /\ L2(history) => L1(history)
        /\ L3(history) => L2(history)
        /\ L4(history) => L3(history)
        /\ L5(history) => L4(history)
        /\ L6(history) => L5(history)

================================================================================
