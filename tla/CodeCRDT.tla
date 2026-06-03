---- MODULE CodeCRDT ----
(***************************************************************************)
(* CodeCRDT operational model with explicit refinement mapping to         *)
(* Memory.tla.                                                             *)
(*                                                                         *)
(* Each agent maintains a local replica computed from a prefix of the     *)
(* global log indexed by syncClock[a]. StartRead populates rv from the   *)
(* replica; CompleteWrite appends to the log AND advances the writing    *)
(* agent's syncClock (local-first apply, the defining property of state- *)
(* based CRDTs); SyncReplica monotonically advances syncClock to model   *)
(* async merge from other agents.                                         *)
(*                                                                         *)
(* REFINEMENT. The mapping phi sends a CodeCRDT state                    *)
(*   (log, inflight, registry, syncClock) to a Memory state              *)
(*   (log, inflight, registry, memory) where memory is the latest-write- *)
(*   wins projection of the log. This module declares the projection;    *)
(*   `Refinement.tla` discharges the refinement obligation                *)
(*   CodeCRDT!Spec => phi!Memory!Spec.                                    *)
(*                                                                         *)
(* TLC harnesses MC_CodeCRDT_RYW.tla and MC_CodeCRDT_AdmitsA1.tla check  *)
(* invariants on this spec directly. Theorem 6.1 (CodeCRDT level         *)
(* placement at L_1 but not L_2) is established by:                       *)
(*   - vacuity of LostSelfWrite under CodeCRDT.Spec (TLC, RYW config);    *)
(*   - violation of StaleGenerationFree under CodeCRDT.Spec (TLC, AdmitsA1*)
(*     config).                                                           *)
(***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS Agents, Cells, Values, Tools, NULL, MaxOps, ExternalCells

VARIABLES log, inflight, syncClock, registry

vars == <<log, inflight, syncClock, registry>>

\* ------- Helpers (must match Memory.tla shapes for refinement) -------

InitialMemory == [c \in Cells |-> NULL]

EmptyOp(a) == [
    pending |-> FALSE, agent |-> a,
    read_set |-> {}, read_values |-> InitialMemory,
    read_registry |-> {}, planned_tool |-> NULL,
    read_time |-> 0,
    write_set |-> {}, write_values |-> InitialMemory,
    write_registry |-> {}, write_time |-> 0,
    io |-> <<>>, co |-> <<>>
]

\* Apply log entries log[k]..log[n] forward over an initial state.
RECURSIVE ApplyForward(_, _, _)
ApplyForward(state, k, n) ==
    IF k > n THEN state
    ELSE LET entry == log[k]
             newState == [c \in Cells |->
                IF c \in entry.write_set
                THEN entry.write_values[c]
                ELSE state[c]]
         IN ApplyForward(newState, k + 1, n)

\* Agent-local replica: the latest-write-wins projection of log[1..syncClock[a]].
Replica(a) == ApplyForward(InitialMemory, 1, syncClock[a])

\* Global memory projection (latest-write-wins over the entire log).
\* This is the phi-image of CodeCRDT state in Memory's state space.
GlobalMemory == ApplyForward(InitialMemory, 1, Len(log))

\* ------- State machine -------

Init ==
    /\ log = <<>>
    /\ inflight = [a \in Agents |-> EmptyOp(a)]
    /\ syncClock = [a \in Agents |-> 0]
    /\ registry = Tools

StartRead(a) ==
    /\ ~inflight[a].pending
    /\ Len(log) < MaxOps
    /\ \E rs \in SUBSET Cells, pt \in registry \cup {NULL}:
        inflight' = [inflight EXCEPT ![a] = [
            pending |-> TRUE, agent |-> a,
            read_set |-> rs,
            read_values |-> Replica(a),
            read_registry |-> registry,
            planned_tool |-> pt,
            read_time |-> Len(log),
            write_set |-> {},
            write_values |-> InitialMemory,
            write_registry |-> {},
            write_time |-> 0,
            io |-> <<>>, co |-> <<>>]]
    /\ UNCHANGED <<log, syncClock, registry>>

CompleteWrite(a) ==
    /\ inflight[a].pending
    /\ Len(log) < MaxOps
    /\ \E ws \in SUBSET Cells, wv \in [Cells -> Values \cup {NULL}]:
        LET newOp == [
            pending |-> FALSE, agent |-> a,
            read_set |-> inflight[a].read_set,
            read_values |-> inflight[a].read_values,
            read_registry |-> inflight[a].read_registry,
            planned_tool |-> inflight[a].planned_tool,
            read_time |-> inflight[a].read_time,
            write_set |-> ws, write_values |-> wv,
            write_registry |-> registry,
            write_time |-> Len(log) + 1,
            io |-> <<>>, co |-> <<>>]
        IN
        /\ log' = Append(log, newOp)
        /\ inflight' = [inflight EXCEPT ![a] = EmptyOp(a)]
        /\ syncClock' = [syncClock EXCEPT ![a] = Len(log) + 1]
    /\ UNCHANGED <<registry>>

SyncReplica(a) ==
    /\ syncClock[a] < Len(log)
    /\ syncClock' = [syncClock EXCEPT ![a] = syncClock[a] + 1]
    /\ UNCHANGED <<log, inflight, registry>>

RemoveTool(t) ==
    /\ t \in registry
    /\ registry' = registry \ {t}
    /\ UNCHANGED <<log, inflight, syncClock>>

Next ==
    \/ \E a \in Agents: StartRead(a) \/ CompleteWrite(a) \/ SyncReplica(a)
    \/ \E t \in Tools: RemoveTool(t)

Spec == Init /\ [][Next]_vars

\* ------- Refinement mapping phi (CodeCRDT state -> Memory state) -------
\* phi keeps log, inflight, registry unchanged and projects syncClock-
\* parameterised replicas to the single global memory variable.
\* Memory.tla's variables are: log, inflight, registry, memory.

phiLog       == log
phiInflight  == inflight
phiRegistry  == registry
phiMemory    == GlobalMemory

\* Memory's state machine instantiated under phi. The refinement theorem
\* CodeCRDT!Spec => phi!Memory!Spec is discharged in Refinement.tla.
MemoryProjection ==
    INSTANCE Memory WITH
        log      <- phiLog,
        inflight <- phiInflight,
        registry <- phiRegistry,
        memory   <- phiMemory

\* ------- Inline anomaly predicates (over the global log) -------

LostSelfWrite ==
    \E i, j \in 1..Len(log):
        /\ log[i].agent = log[j].agent
        /\ log[i].write_time < log[j].read_time
        /\ \E c \in log[i].write_set \cap log[j].read_set:
            ~ \E k \in 1..Len(log):
                /\ log[k].write_time >= log[i].write_time
                /\ log[k].write_time <= log[j].read_time
                /\ c \in log[k].write_set
                /\ log[k].write_values[c] = log[j].read_values[c]

LostSelfWriteFree == ~LostSelfWrite

StaleGeneration ==
    \E i, j \in 1..Len(log):
        /\ i # j
        /\ log[i].agent # log[j].agent
        /\ log[i].read_time < log[j].write_time
        /\ log[j].write_time < log[i].write_time
        /\ \E c \in log[i].read_set \cap log[j].write_set:
            log[i].read_values[c] # log[j].write_values[c]

StaleGenerationFree == ~StaleGeneration

====
