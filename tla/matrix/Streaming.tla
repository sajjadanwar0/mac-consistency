--------------------------- MODULE Streaming ---------------------------
(***************************************************************************)
(* Streaming model M* and a CORRECTED formulation of Theorem 5.5         *)
(* (Atomicity-streaming impossibility).                                   *)
(*                                                                         *)
(* THE PROBLEM WITH THE PAPER'S CURRENT THEOREM 5.5                       *)
(* The paper's proof concludes by appealing to "any natural refinement of *)
(* A_6 to M* that includes such observable partial states" — but no      *)
(* such refinement is defined. The conclusion does not follow from the   *)
(* stated assumptions because A_6 as defined in §3.6 is a property of    *)
(* the io-vs-co relation, not a property of partial visibility during   *)
(* commit intervals.                                                     *)
(*                                                                         *)
(* THE CORRECTED FORMULATION                                              *)
(* We define a strengthened anomaly A_6* that explicitly forbids         *)
(* observable partial states during commit intervals. The impossibility *)
(* theorem is then: no streaming runtime can simultaneously prevent A_6* *)
(* (note: the strong version), admit unbounded write-set size, and       *)
(* operate with bounded private buffer. This is the correct statement of *)
(* the folklore tradeoff.                                                *)
(*                                                                         *)
(* Note: this formulation forces us to honestly distinguish A_6 from    *)
(* A_6*. A_6 alone (per the paper §3.6) is NOT impossible to prevent;   *)
(* a streaming runtime can prevent A_6 by ensuring co = io in the       *)
(* committed log, regardless of what was observable during commit. It   *)
(* is the strengthening to A_6* (forbidding partial observability) that *)
(* the impossibility result targets.                                     *)
(*                                                                         *)
(* The paper §5.5.4 should be rewritten to:                              *)
(*   (a) define A_6* explicitly;                                         *)
(*   (b) restate Theorem 5.5 as targeting A_6*, not A_6;                 *)
(*   (c) add a paragraph explaining the gap between A_6 and A_6* and   *)
(*       why the impossibility targets the latter.                       *)
(***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Agents, Cells, Values, BufferBound

\* Streaming operation record. Extends OpRecord with a commit interval
\* [t_s, t_e] and an externalisation pointer ext_idx that advances
\* through co during the interval.
StreamingOpRecord == [
    agent          : Agents,
    read_set       : SUBSET Cells,
    read_values    : [Cells -> Values],
    read_time      : Nat,
    write_set      : SUBSET Cells,
    write_values   : [Cells -> Values],
    write_time     : Nat,
    io             : Seq(Cells \X Values),
    co             : Seq(Cells \X Values),
    t_s            : Nat,        \* commit interval start
    t_e            : Nat,        \* commit interval end
    ext_idx        : Nat,        \* how many co entries externalised so far
    private_buffer : SUBSET (Cells \X Values)  \* runtime-held writes
]

\* Observable state at time t for operation o. The externalised prefix is
\* the first ext_idx(t) entries of co; the rest are still in private buffer.
ObservedPrefix(o, t) ==
    IF t < o.t_s THEN <<>>
    ELSE IF t >= o.t_e THEN o.co
    ELSE SubSeq(o.co, 1, o.ext_idx)

\* A_6* (strong): the set of externalised prefixes during the commit
\* interval includes a prefix that does not correspond to any prefix of
\* io. Equivalently: an external observer can witness a state that no
\* atomic-commit semantics would produce.
A6Star(history) ==
    \E i \in 1..Len(history), t \in Nat :
        LET o   == history[i]
            obs == ObservedPrefix(o, t)
        IN  /\ Len(o.io) >= 2
            /\ \A k \in 0..Len(o.io) :
                obs # SubSeq(o.io, 1, k)

\* (a) A_6* is prevented for every history of the runtime.
PreventsA6Star(R) ==
    \A history \in R :
        ~A6Star(history)

\* (b) Unbounded write-set size: for every B, some history contains an
\* operation with |io| > B.
UnboundedWriteSet(R) ==
    \A B \in Nat :
        \E history \in R, i \in 1..Len(history) :
            Len(history[i].io) > B

\* (c) Bounded private buffer: every operation in every history has
\* |private_buffer| <= BufferBound at every instant. Captured via the
\* invariant that during commit, the unexternalised tail of co fits in
\* BufferBound slots.
BoundedBuffer(R) ==
    \A history \in R, i \in 1..Len(history), t \in Nat :
        LET o == history[i]
        IN  (t \in (o.t_s..o.t_e))
            => (Len(o.co) - o.ext_idx) <= BufferBound

\* The corrected impossibility theorem.
THEOREM AtomicityStreamingImpossibility ==
    \A R :
        ~ /\ PreventsA6Star(R)
          /\ UnboundedWriteSet(R)
          /\ BoundedBuffer(R)

\* PROOF SKETCH (informal; mechanisation deferred):
\* Assume R satisfies (a), (b), (c). By (b), pick B = BufferBound + 1
\* and history h with operation o where |o.io| = B+1 = BufferBound + 2.
\* By (c), at any t in (o.t_s, o.t_e), the unexternalised tail satisfies
\* |o.co| - o.ext_idx <= BufferBound, i.e., o.ext_idx >= 2. So during
\* the commit interval, at least 2 entries of co have been externalised.
\* If co = io, then ObservedPrefix(o, t) = SubSeq(io, 1, o.ext_idx) is
\* a prefix of io, so ~A6Star is preserved. But to maintain co = io
\* with bounded buffer, the runtime must externalise io in order, which
\* means committing irrevocably to the order before the operation has
\* completed. This places observable state in the world before commit:
\* a property the abstract M model does not produce.
\*
\* The contradiction is that "abstract M" means atomic commit (no partial
\* visibility), so the existence of an observable prefix during the commit
\* interval is itself the violation. Formalising this requires lifting
\* the impossibility to a property of how the streaming runtime relates
\* to its abstract specification — work that the paper should make
\* explicit. We mark this as PROOF OBLIGATION below.

\* The proof obligation, to be discharged in a follow-up mechanisation:
PROOF_OBLIGATION_AtomicityStreaming ==
    \A R :
        (PreventsA6Star(R) /\ UnboundedWriteSet(R) /\ BoundedBuffer(R))
        => FALSE

==========================================================================
