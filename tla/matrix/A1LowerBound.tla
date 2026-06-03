--------------------------- MODULE A1LowerBound ---------------------------
(***************************************************************************)
(* Theorem 5.1 (Generation-phase lower bound for A_1) mechanised at the   *)
(* trace level.                                                            *)
(*                                                                         *)
(* STATEMENT. For any history h with ~StaleGeneration(h), every operation *)
(* i satisfies ReadSetLock(h, i) \/ ValueAgreement(h, i).                  *)
(*                                                                         *)
(* The paper's three-way (L)/(V)/(I) split is operational; at the trace   *)
(* level (V) and (I) coincide. The theorem below is the trace-level       *)
(* version; the paper §5.5.1 should add a paragraph explaining the        *)
(* operational-vs-trace collapse.                                          *)
(*                                                                         *)
(* The proof additionally requires a non-overlapping property of M: no    *)
(* two operations of the same agent overlap in [read_time, write_time].  *)
(* This is enforced by the inv-OneInFlight invariant of Memory.tla and    *)
(* lifted to histories via the NonOverlappingAgent predicate below. The   *)
(* lifting itself is an inductive invariance proof on Memory.tla's Spec. *)
(***************************************************************************)

EXTENDS Memory, Anomalies, Mechanisms, TLAPS

\* History-level lifting of inv-OneInFlight.
NonOverlappingAgent(h) ==
    \A i, j \in 1..Len(h) :
        (i # j /\ h[i].agent = h[j].agent)
        => (h[i].write_time <= h[j].read_time
            \/ h[j].write_time <= h[i].read_time)

\* The trace-level lower bound. Note the NonOverlappingAgent hypothesis,
\* which is a property of M established separately by an inductive
\* invariance proof on Memory.Spec (see Memory.tla's NonOverlappingInv).
THEOREM A1LowerBoundTrace ==
    \A h \in Seq(OpRecord) :
        (NonOverlappingAgent(h) /\ ~StaleGeneration(h))
        =>
        \A i \in 1..Len(h) :
            A1Mechanism(h, i)
PROOF
    <1>1. SUFFICES ASSUME NEW h \in Seq(OpRecord),
                          NonOverlappingAgent(h),
                          ~StaleGeneration(h),
                          NEW i \in 1..Len(h),
                          ~A1Mechanism(h, i)
                   PROVE FALSE
        OBVIOUS
    <1>2. /\ ~ReadSetLock(h, i)
          /\ ~ValueAgreement(h, i)
        BY <1>1 DEF A1Mechanism
    <1>3. \E k \in 1..Len(h) :
            /\ k # i
            /\ h[k].write_time > h[i].read_time
            /\ h[k].write_time < h[i].write_time
            /\ \E c \in h[i].read_set \cap h[k].write_set :
                h[k].write_values[c] # h[i].read_values[c]
        BY <1>2 DEF ReadSetLock, ValueAgreement
    <1>4. PICK k \in 1..Len(h) :
            /\ k # i
            /\ h[k].write_time > h[i].read_time
            /\ h[k].write_time < h[i].write_time
            /\ \E c \in h[i].read_set \cap h[k].write_set :
                h[k].write_values[c] # h[i].read_values[c]
        BY <1>3
    <1>5. h[i].agent # h[k].agent
        \* By NonOverlappingAgent: if same agent, intervals must not
        \* overlap, but k's write_time is strictly between i's read_time
        \* and write_time, so they overlap, contradicting same agent.
        BY <1>1, <1>4 DEF NonOverlappingAgent
    <1>6. StaleGeneration(h)
        BY <1>4, <1>5 DEF StaleGeneration
    <1> QED BY <1>1, <1>6

==========================================================================
