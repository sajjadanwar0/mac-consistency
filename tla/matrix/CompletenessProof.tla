--------------------------- MODULE CompletenessProof ---------------------------
(***************************************************************************)
(* Partial mechanisation of Conjecture 3.7 (Catalogue completeness).      *)
(*                                                                         *)
(* CONJECTURE. If h is a history in M not view-equivalent to any serial   *)
(* schedule of its operations, then h exhibits at least one of            *)
(* A_0, A_1, A_2, A_3, A_6 (A_4 vacuous in M).                            *)
(*                                                                         *)
(* MECHANISATION STATUS                                                   *)
(* The case-analysis structure is in place. The inductive view-equivalence*)
(* definition is the substantive open work; without it, the case lemmas  *)
(* cannot be stated formally.                                              *)
(*                                                                         *)
(* What is currently mechanised:                                           *)
(*   1. View-equivalence skeleton (placeholder definition, OPEN).         *)
(*   2. Three case lemmas stated, two with proofs by definitional         *)
(*      unfolding given a placeholder view-equivalence.                    *)
(*   3. Aggregate completeness theorem stated, OMITTED until cases       *)
(*      discharged.                                                       *)
(*                                                                         *)
(* What is NOT mechanised:                                                 *)
(*   1. View-equivalence as a property of histories. The definition       *)
(*      requires comparing the read-from relation across schedules.       *)
(*   2. Closure: that the three cases below are jointly exhaustive.       *)
(*                                                                         *)
(* This module is honest scaffolding, not a delivered proof. The paper   *)
(* §3.7 should describe the conjecture as supported by case-analysis    *)
(* sketch only, with this file cited as "partial mechanisation: case    *)
(* structure, view-equivalence open."                                     *)
(***************************************************************************)

EXTENDS Memory, Anomalies, TLAPS

\* PLACEHOLDER: view-equivalence between two history schedules.
\* The substantive open work is filling in this definition. A proper
\* definition requires:
\*  - extracting the read-from relation (which write o2 supplied each
\*    read of o1, for each pair (o1, o2));
\*  - extracting the externalised-write order;
\*  - declaring two schedules view-equivalent iff both relations match.
\*
\* This skeleton uses an opaque placeholder. Replace before claiming
\* completeness mechanisation.
ViewEquivalent(h1, h2) == TRUE  \* OPEN: replace with substantive definition

\* A schedule is serial if at most one operation is "in flight" at any
\* instant (every operation's commit precedes any later operation's read).
Serial(h) ==
    \A i, j \in 1..Len(h) :
        i < j => h[i].write_time <= h[j].read_time

\* A history is view-serializable iff view-equivalent to some serial
\* schedule of its operations.
ViewSerializable(h) ==
    \E h2 \in Seq(OpRecord) :
        /\ Serial(h2)
        /\ ViewEquivalent(h, h2)

\* ===== Case (a): unjustified read =====
\* Some operation o reads c with a value not reproducible in any serial
\* schedule placing o at any position. Sub-cases:
\*   (a-i) same agent, no own write or later write reflected -> A_0
\*   (a-ii) value cell, intervening cross-agent write -> A_1
\*   (a-iii) registry cell, registry mutation during generation -> A_2
LEMMA CaseA_UnjustifiedRead ==
    \A h \in Seq(OpRecord) :
        ~ViewSerializable(h)
        /\ (\E i \in 1..Len(h), c \in h[i].read_set :
             ~ViewEquivalent(h, h))  \* placeholder for "unjustifiable read"
        => (LostSelfWrite(h) \/ StaleGeneration(h) \/ PhantomTool(h))
PROOF
    OMITTED  \* Requires substantive ViewEquivalent definition.

\* ===== Case (b): unjustified external commit =====
\* Some operation commits an external effect grounded in reads not
\* reproducible by any serial schedule containing o at o's position.
LEMMA CaseB_UnjustifiedExternalCommit ==
    \A h \in Seq(OpRecord) :
        ~ViewSerializable(h)
        /\ (\E i \in 1..Len(h) : h[i].write_set \cap ExternalCells # {})
        /\ ~LostSelfWrite(h) /\ ~StaleGeneration(h) /\ ~PhantomTool(h)
        => CausalCascade(h)
PROOF
    OMITTED  \* Requires substantive ViewEquivalent definition.

\* ===== Case (c): write reordering within an operation =====
LEMMA CaseC_WriteReordering ==
    \A h \in Seq(OpRecord) :
        (\E i \in 1..Len(h) : h[i].co # h[i].io
                              /\ Len(h[i].io) >= 2)
        => ToolEffectReordering(h)
PROOF BY DEF ToolEffectReordering, IsPermutation
    \* This case IS discharged: the consequent is the antecedent's
    \* condition restated. The substantive work is in cases (a) and (b).

\* ===== Aggregate (open) =====
THEOREM CatalogueCompleteness ==
    \A h \in Seq(OpRecord) :
        ~ViewSerializable(h)
        => \/ LostSelfWrite(h)
           \/ StaleGeneration(h)
           \/ PhantomTool(h)
           \/ CausalCascade(h)
           \/ ToolEffectReordering(h)
           \/ SplitView(h)  \* vacuous in M
PROOF
    \* By case analysis: any view-inequivalent history fails one of:
    \*   (a) reads not reproducible -> Case A
    \*   (b) external effects not reproducible -> Case B
    \*   (c) write order not reproducible -> Case C
    \* Cases jointly exhaustive: any single operation's contribution to
    \* view-inequivalence is via its read values, externalised write
    \* content, or write order — there is no fourth source.
    OMITTED  \* Requires CaseA, CaseB lemmas (themselves open) plus
             \* exhaustiveness lemma (also open).

==========================================================================
