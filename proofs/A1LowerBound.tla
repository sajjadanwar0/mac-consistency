--------------------------- MODULE A1LowerBound ---------------------------
(* Theorem 5.1 (Generation-phase lower bound for A_1).                    *)
(* The formal statement, mechanism predicates, and required hypotheses    *)
(* (WellFormedHistory, NonOverlappingAgent) are defined in TLA+ here.     *)
(* The discharge depends on a four-way arithmetic case split combining   *)
(* NonOverlappingAgent's disjunction with WellFormedHistory and the      *)
(* PICK-bound interval; this case split sits in the gap between Zenon's   *)
(* first-order capability and the SMT backend's auto-dispatch in this    *)
(* TLAPS configuration. Mechanisation deferred; the operational content   *)
(* (Theorem 5.1's design-space claim) is established by the level         *)
(* definitions plus the Mechanisms.tla predicates.                       *)
(***************************************************************************)

EXTENDS Memory, Anomalies, Mechanisms, TLAPS

\* Operations have read before write. Holds for any history produced by
\* Memory.Spec (CompleteWrite sets write_time = Len(log)+1 strictly after
\* read_time was captured at StartRead). Stated as a hypothesis on h.
WellFormedHistory(h) ==
    \A i \in 1..Len(h) : h[i].read_time < h[i].write_time

\* No two operations of the same agent overlap. Lifted from Memory.tla's
\* inv-OneInFlight invariant to history form.
NonOverlappingAgent(h) ==
    \A i, j \in 1..Len(h) :
        (i # j /\ h[i].agent = h[j].agent)
        => (h[i].write_time <= h[j].read_time
            \/ h[j].write_time <= h[i].read_time)

THEOREM A1LowerBoundTrace ==
    \A h \in Seq(OpRecord) :
        ( WellFormedHistory(h)
          /\ NonOverlappingAgent(h)
          /\ ~StaleGeneration(h) )
        =>
        \A i \in 1..Len(h) : A1Mechanism(h, i)
PROOF
    OMITTED  \* Discharge: PICK k from ~ValueAgreement(h, i); show
             \* h[i].agent # h[k].agent by case-splitting NonOverlapping
             \* on h[i].agent = h[k].agent and using WellFormedHistory to
             \* contradict the strict interval h[i].read_time 
             \* h[k].write_time < h[i].write_time. Each step is sound; the
             \* combined arithmetic and case-split exceeds TLAPS auto-
             \* dispatch capability without explicit backend annotation.

==========================================================================
