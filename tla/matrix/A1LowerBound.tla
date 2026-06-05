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
(* version; the paper section 5.5.1 should add a paragraph explaining the *)
(* operational-vs-trace collapse.                                          *)
(*                                                                         *)
(* The proof requires two well-formedness properties of M, both lifted    *)
(* from Memory.tla's Spec to histories as hypotheses (each discharged by  *)
(* a separate inductive invariance proof on Memory.Spec):                  *)
(*                                                                         *)
(*   1. NonOverlappingAgent(h): no two operations of the same agent       *)
(*      overlap in [read_time, write_time]. History-level lifting of the  *)
(*      inv-OneInFlight invariant.                                         *)
(*                                                                         *)
(*   2. MonotonicOp(h): each operation reads no later than it writes      *)
(*      (read_time <= write_time). In M, read_time is fixed at StartRead  *)
(*      (an earlier Len(log)) and write_time at CompleteWrite (Len(log)+1 *)
(*      later), so read_time < write_time holds. OpRecord types both as   *)
(*      Nat without this ordering, so it is supplied as a hypothesis;     *)
(*      without it the same-agent overlap contradiction in <1>5 fails.    *)
(***************************************************************************)

EXTENDS Memory, Anomalies, Mechanisms, TLAPS

NonOverlappingAgent(h) ==
    \A i, j \in 1..Len(h) :
        (i # j /\ h[i].agent = h[j].agent)
        => (h[i].write_time <= h[j].read_time
            \/ h[j].write_time <= h[i].read_time)

MonotonicOp(h) ==
    \A m \in 1..Len(h) : h[m].read_time <= h[m].write_time

THEOREM A1LowerBoundTrace ==
    \A h \in Seq(OpRecord) :
        (NonOverlappingAgent(h) /\ MonotonicOp(h) /\ ~StaleGeneration(h))
        =>
        \A i \in 1..Len(h) :
            A1Mechanism(h, i)
PROOF
    <1>1. SUFFICES ASSUME NEW h \in Seq(OpRecord),
                          NonOverlappingAgent(h),
                          MonotonicOp(h),
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
        <2> SUFFICES ASSUME h[i].agent = h[k].agent
                     PROVE FALSE
            OBVIOUS
        <2>1. h[i] \in OpRecord /\ h[k] \in OpRecord
            BY <1>1, <1>4
        <2>2. h[k].read_time <= h[k].write_time
            BY <1>1, <1>4 DEF MonotonicOp
        <2>3. h[i].write_time <= h[k].read_time
              \/ h[k].write_time <= h[i].read_time
            BY <1>1, <1>4 DEF NonOverlappingAgent
        <2> QED
            BY <2>1, <2>2, <2>3, <1>4 DEF OpRecord
    <1>6. StaleGeneration(h)
        BY <1>4, <1>5 DEF StaleGeneration
    <1> QED BY <1>1, <1>6

==========================================================================
