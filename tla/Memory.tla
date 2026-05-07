--------------------------------- MODULE Memory ---------------------------------
EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS Agents, Cells, Values, NULL, MaxOps, Tools

ASSUME NULL \notin Values
ASSUME NULL \notin Tools

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
    write_time     : Nat
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
    write_time     |-> 0
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

(* StartRead: agent reads memory and a registry snapshot, optionally
   picks one tool from the snapshot to plan to invoke later. *)
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
             write_time     |-> 0
         ]]
    /\ UNCHANGED <<memory, log, registry>>

(* CompleteWrite: agent commits, recording the registry state at write_time. *)
CompleteWrite(a) ==
    /\ inflight[a].pending = TRUE
    /\ \E ws \in SUBSET Cells, wv \in [Cells -> Values] :
         LET op == [
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
                write_time     |-> Len(log) + 1
             ]
         IN  /\ memory'   = [c \in Cells |->
                                IF c \in ws THEN wv[c] ELSE memory[c]]
             /\ log'      = Append(log, op)
             /\ inflight' = [inflight EXCEPT ![a] = IdleOp(a)]
    /\ UNCHANGED registry

(* RemoveTool: at any moment, a tool may be removed from the registry.
   This is what creates the gap between an agent's planned_tool and the
   registry contents at write_time. *)
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
