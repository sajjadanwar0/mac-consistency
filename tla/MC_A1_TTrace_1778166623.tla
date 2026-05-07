---- MODULE MC_A1_TTrace_1778166623 ----
EXTENDS Sequences, TLCExt, MC_A1, MC_A1_TEConstants, Toolbox, Naturals, TLC

_expression ==
    LET MC_A1_TEExpression == INSTANCE MC_A1_TEExpression
    IN MC_A1_TEExpression!expression
----

_trace ==
    LET MC_A1_TETrace == INSTANCE MC_A1_TETrace
    IN MC_A1_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        memory = ((c1 :> "NULL"))
        /\
        log = (<<>>)
        /\
        inflight = ((a1 :> [agent |-> a1, read_set |-> {}, read_values |-> (c1 :> "NULL"), read_time |-> 0, write_set |-> {}, write_values |-> (c1 :> "NULL"), write_time |-> 0] @@ a2 :> "NONE"))
    )
----

_init ==
    /\ inflight = _TETrace[1].inflight
    /\ memory = _TETrace[1].memory
    /\ log = _TETrace[1].log
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ inflight  = _TETrace[i].inflight
        /\ inflight' = _TETrace[j].inflight
        /\ memory  = _TETrace[i].memory
        /\ memory' = _TETrace[j].memory
        /\ log  = _TETrace[i].log
        /\ log' = _TETrace[j].log

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("MC_A1_TTrace_1778166623.json", _TETrace)

=============================================================================

 Note that you can extract this module `MC_A1_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `MC_A1_TEExpression.tla` file takes precedence 
  over the module `MC_A1_TEExpression` below).

---- MODULE MC_A1_TEExpression ----
EXTENDS Sequences, TLCExt, MC_A1, MC_A1_TEConstants, Toolbox, Naturals, TLC

expression == 
    [
        \* To hide variables of the `MC_A1` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        inflight |-> inflight
        ,memory |-> memory
        ,log |-> log
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_inflightUnchanged |-> inflight = inflight'
        
        \* Format the `inflight` variable as Json value.
        \* ,_inflightJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(inflight)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_inflightModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].inflight # _TETrace[s-1].inflight
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE MC_A1_TETrace ----
\*EXTENDS IOUtils, MC_A1, MC_A1_TEConstants, TLC
\*
\*trace == IODeserialize("MC_A1_TTrace_1778166623.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE MC_A1_TETrace ----
EXTENDS MC_A1, MC_A1_TEConstants, TLC

trace == 
    <<
    ([memory |-> (c1 :> "NULL"),log |-> <<>>,inflight |-> (a1 :> "NONE" @@ a2 :> "NONE")]),
    ([memory |-> (c1 :> "NULL"),log |-> <<>>,inflight |-> (a1 :> [agent |-> a1, read_set |-> {}, read_values |-> (c1 :> "NULL"), read_time |-> 0, write_set |-> {}, write_values |-> (c1 :> "NULL"), write_time |-> 0] @@ a2 :> "NONE")])
    >>
----


=============================================================================

---- MODULE MC_A1_TEConstants ----
EXTENDS MC_A1

CONSTANTS a1, a2, c1, v1, v2

=============================================================================

---- CONFIG MC_A1_TTrace_1778166623 ----
CONSTANTS
    Agents = { a1 , a2 }
    Cells = { c1 }
    Values = { v1 , v2 }
    NULL = "NULL"
    MaxOps = 4
    v1 = v1
    v2 = v2
    a2 = a2
    c1 = c1
    a1 = a1

INVARIANT
    _inv

CHECK_DEADLOCK
    \* CHECK_DEADLOCK off because of PROPERTY or INVARIANT above.
    FALSE

INIT
    _init

NEXT
    _next

CONSTANT
    _TETrace <- _trace

ALIAS
    _expression
=============================================================================
\* Generated on Thu May 07 20:10:24 PKT 2026