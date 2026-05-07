--------------------------------- MODULE Memory ---------------------------------
EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS Agents, Cells, Values, NULL, MaxOps, Tools, ExternalCells

ASSUME NULL \notin Values
ASSUME NULL \notin Tools
ASSUME ExternalCells \subseteq Cells

VARIABLES memory, log, inflight, registry

vars == <<memory, log, inflight, registry>>

OpRecord == [
    pending        : BOOLEAN,
    agent          : Agents,
    read_set       : SUBSET Cells,
    read_values    : [Cells -> Values \cup {NULL}],
    read_registry  : SUBSET Tools,
    planned_tool   : Tools \cup {NULL},
    read_time      : Nat,
    write_set      : SUBSET Cells,
    write_values   : [Cells -> Values \cup {NULL}],
    write_registry : SUBSET Tools,
    write_time     : Nat,
    reordered      : BOOLEAN
]

IdleOp(a) == [
    pending        |-> FALSE,
    agent          |-> a,
    read_set       |-> {},
    read_values    |-> [c \in Cells |-> NULL],
    read_registry  |-> {},
    planned_tool   |-> NULL,
    read_time      |-> 0,
    write_set      |-> {},
    write_values   |-> [c \in Cells |-> NULL],
    write_registry |-> {},
    write_time     |-> 0,
    reordered      |-> FALSE
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
    /\ memory   = [c \in Cells |-> NULL]
    /\ log      = << >>
    /\ inflight = [a \in Agents |-> IdleOp(a)]
    /\ registry = Tools

StartRead(a) ==
    /\ inflight[a].pending = FALSE
    /\ Len(log) < MaxOps
    /\ \E rs \in SUBSET Cells, pt \in registry \cup {NULL} :
         inflight' = [inflight EXCEPT ![a] = [
             pending        |-> TRUE,
             agent          |-> a,
             read_set       |-> rs,
             read_values    |-> [c \in Cells |->
                                   IF c \in rs THEN memory[c] ELSE NULL],
             read_registry  |-> registry,
             planned_tool   |-> pt,
             read_time      |-> Len(log),
             write_set      |-> {},
             write_values   |-> [c \in Cells |-> NULL],
             write_registry |-> {},
             write_time     |-> 0,
             reordered      |-> FALSE
         ]]
    /\ UNCHANGED <<memory, log, registry>>

CompleteWrite(a) ==
    /\ inflight[a].pending = TRUE
    /\ \E ws \in SUBSET Cells, wv \in [Cells -> Values], r \in BOOLEAN :
         \* Reordering only makes sense for operations with multiple writes.
         /\ (r => Cardinality(ws) >= 2)
         /\ LET op == [
                  pending        |-> FALSE,
                  agent          |-> a,
                  read_set       |-> inflight[a].read_set,
                  read_values    |-> inflight[a].read_values,
                  read_registry  |-> inflight[a].read_registry,
                  planned_tool   |-> inflight[a].planned_tool,
                  read_time      |-> inflight[a].read_time,
                  write_set      |-> ws,
                  write_values   |-> [c \in Cells |->
                                        IF c \in ws THEN wv[c] ELSE NULL],
                  write_registry |-> registry,
                  write_time     |-> Len(log) + 1,
                  reordered      |-> r
               ]
            IN  /\ memory'   = [c \in Cells |->
                                  IF c \in ws THEN wv[c] ELSE memory[c]]
                /\ log'      = Append(log, op)
                /\ inflight' = [inflight EXCEPT ![a] = IdleOp(a)]
    /\ UNCHANGED registry

RemoveTool(t) ==
    /\ t \in registry
    /\ registry' = registry \ {t}
    /\ UNCHANGED <<memory, log, inflight>>

Next ==
    \/ \E a \in Agents : StartRead(a) \/ CompleteWrite(a)
    \/ \E t \in Tools  : RemoveTool(t)

Spec == Init /\ [][Next]_vars

TypeOK ==
    /\ memory   \in [Cells -> Values \cup {NULL}]
    /\ log      \in Seq(OpRecord)
    /\ inflight \in [Agents -> OpRecord]
    /\ registry \in SUBSET Tools

================================================================================
