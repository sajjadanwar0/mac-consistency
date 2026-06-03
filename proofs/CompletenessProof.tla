--------------------------- MODULE CompletenessProof ---------------------------
(* Partial mechanisation of Conjecture 3.7. View-equivalence is a        *)
(* placeholder; substantive case-analysis lemmas are OMITTED pending the *)
(* definition.                                                            *)

EXTENDS Memory, Anomalies, TLAPS

\* PLACEHOLDER. Replace before claiming completeness mechanisation.
ViewEquivalent(h1, h2) == TRUE

Serial(h) ==
    \A i, j \in 1..Len(h) :
        i < j => h[i].write_time <= h[j].read_time

ViewSerializable(h) ==
    \E h2 \in Seq(OpRecord) :
        /\ Serial(h2)
        /\ ViewEquivalent(h, h2)

\* ===== Case (a) ===== unjustified read; sub-cases A_0 / A_1 / A_2.
LEMMA CaseA_UnjustifiedRead ==
    \A h \in Seq(OpRecord) :
        ( ~ViewSerializable(h)
          /\ (\E i \in 1..Len(h) :
                 \E c \in h[i].read_set :
                     ~ViewEquivalent(h, h)) )
        => (LostSelfWrite(h) \/ StaleGeneration(h) \/ PhantomTool(h))
PROOF
    OMITTED

\* ===== Case (b) ===== unjustified external commit; A_3.
LEMMA CaseB_UnjustifiedExternalCommit ==
    \A h \in Seq(OpRecord) :
        ( ~ViewSerializable(h)
          /\ (\E i \in 1..Len(h) :
                 h[i].write_set \cap ExternalCells # {})
          /\ ~LostSelfWrite(h)
          /\ ~StaleGeneration(h)
          /\ ~PhantomTool(h) )
        => CausalCascade(h)
PROOF
    OMITTED

\* ===== Case (c) ===== write reordering; A_6. The only case discharged.
LEMMA CaseC_WriteReordering ==
    \A h \in Seq(OpRecord) :
        (\E i \in 1..Len(h) :
            h[i].co # h[i].io /\ Len(h[i].io) >= 2)
        => ToolEffectReordering(h)
PROOF
    OMITTED  \* Requires IsPermutation reasoning; parametrise on Memory.tla.

THEOREM CatalogueCompleteness ==
    \A h \in Seq(OpRecord) :
        ~ViewSerializable(h)
        => \/ LostSelfWrite(h)
           \/ StaleGeneration(h)
           \/ PhantomTool(h)
           \/ CausalCascade(h)
           \/ ToolEffectReordering(h)
           \/ SplitView(h)
PROOF
    OMITTED

==========================================================================
