--------------------------------- MODULE Memory ---------------------------------
EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS Agents, Cells, Values, NULL, MaxOps

ASSUME NULL \notin Values

VARIABLES memory, log, inflight

vars == <<memory, log, inflight>>

(* An OpRecord now carries a `pending` flag so that idle and active states
   are both records of the same shape. This keeps TLC's strict equality
   checker happy. *)
OpRecord == [
    pending      : BOOLEAN,
    agent        : Agents,
    read_set     : SUBSET Cells,
    read_values  : [Cells -> Values \cup {NULL}],
    read_time    : Nat,
    write_set    : SUBSET Cells,
    write_values : [Cells -> Values \cup {NULL}],
    write_time   : Nat
]

(* Default record used to populate inflight slots for idle agents. *)
IdleOp(a) == [
    pending      |-> FALSE,
    agent        |-> a,
    read_set     |-> {},
    read_values  |-> [c \in Cells |-> NULL],
    read_time    |-> 0,
    write_set    |-> {},
    write_values |-> [c \in Cells |-> NULL],
    write_time   |-> 0
]

LatestWriteBefore(c, t) ==
    LET writes == { i \in 1..Len(log) :
                      /\ c \in log[i].write_set
                      /\ log[i].write_time < t }
    IN  IF writes = {} THEN NULL
        ELSE LET i == CHOOSE i \in writes :
                          \A j \in writes : log[j].write_time =< log[i].write_time
             IN log[i].write_values[c]

Init ==
    /\ memory = [c \in Cells |-> NULL]
    /\ log = << >>
    /\ inflight = [a \in Agents |-> IdleOp(a)]

StartRead(a) ==
    /\ inflight[a].pending = FALSE
    /\ Len(log) < MaxOps
    /\ \E rs \in SUBSET Cells :
         inflight' = [inflight EXCEPT ![a] = [
             pending      |-> TRUE,
             agent        |-> a,
             read_set     |-> rs,
             read_values  |-> [c \in Cells |->
                                 IF c \in rs THEN memory[c] ELSE NULL],
             read_time    |-> Len(log),
             write_set    |-> {},
             write_values |-> [c \in Cells |-> NULL],
             write_time   |-> 0
         ]]
    /\ UNCHANGED <<memory, log>>

CompleteWrite(a) ==
    /\ inflight[a].pending = TRUE
    /\ \E ws \in SUBSET Cells, wv \in [Cells -> Values] :
         LET op == [
                pending      |-> FALSE,
                agent        |-> a,
                read_set     |-> inflight[a].read_set,
                read_values  |-> inflight[a].read_values,
                read_time    |-> inflight[a].read_time,
                write_set    |-> ws,
                write_values |-> [c \in Cells |->
                                    IF c \in ws THEN wv[c] ELSE NULL],
                write_time   |-> Len(log) + 1
             ]
         IN  /\ memory' = [c \in Cells |->
                              IF c \in ws THEN wv[c] ELSE memory[c]]
             /\ log' = Append(log, op)
             /\ inflight' = [inflight EXCEPT ![a] = IdleOp(a)]

Next == \E a \in Agents : StartRead(a) \/ CompleteWrite(a)

Spec == Init /\ [][Next]_vars

TypeOK ==
    /\ memory \in [Cells -> Values \cup {NULL}]
    /\ log \in Seq(OpRecord)
    /\ inflight \in [Agents -> OpRecord]

================================================================================
