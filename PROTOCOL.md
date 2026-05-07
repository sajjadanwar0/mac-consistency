# Protocol Document

**Project:** mac-consistency
**Date authored:** [fill in on commit]
**Author:** [your name]

This document records the scope, methodology, and stopping criteria for this
research project. It is committed at project start and is **not edited
afterwards**. If a deviation from this document becomes necessary during
execution, the deviation is recorded as an addendum dated on the day it is
made, with the reasoning behind it.

## Scope commitments

### Anomalies

The catalogue contains exactly **six** anomalies:

1. A1. Stale-Generation
2. A2. Phantom-Tool
3. A3. Causal-Cascade
4. A4. Split-View
5. A5. Long-Generation Window
6. A6. Tool-Effect Reordering

A seventh anomaly will not be added during the project. If a candidate seventh
anomaly is identified, it is recorded in `FUTURE_WORK.md` and not pursued in
this paper.

### Levels

The hierarchy contains exactly **seven** consistency levels:

- L0. Eventually Visible
- L1. Per-Agent Read-Your-Writes
- L2. Generation Snapshot
- L3. Causal-LLM
- L4. Tool-Atomic
- L5. Agent-Snapshot
- L6. Agent-Serialisable

The fallback position, if mid-project assessment shows the full hierarchy is
not tractable, is to reduce to four levels: **L0, L2, L3, L5**. This fallback
is preregistered.

### Code base

The Rust reference implementation is hard-capped at **5,000 lines of safe Rust**.
If implementation cannot fit within this cap, the design is wrong and is
simplified, not extended.

### Evaluation

The empirical evaluation does **not** use LLM-as-judge or any subjective
output grading. All measurements are deterministic and replayable. Agent
counts are restricted to N in {4, 8, 16}. Larger N is out of scope.

## Methodology commitments

- All level specifications are written in TLA+ before any Rust is written.
- The hierarchy theorem is stated formally before any proofs are attempted.
- Every anomaly witness is TLC-verified at small N (typically N=2 or N=3)
  before TLAPS proofs are attempted.
- Trace-conformance tests check the Rust implementation against the TLA+
  specifications using deterministic seeded execution.

## Hard stopping criteria

### Mid-project pivot point: end of week 8

At the end of week 8, evaluate whether TLAPS proofs of the hierarchy theorem
are converging. The decision criterion is binary:

- **Continue** if at least three pairs of adjacent levels have completed proofs.
- **Pivot to fallback** (the four-level hierarchy) otherwise.

### Final stop: end of week 22

At the end of week 22, the paper is submitted to TMLR (or the chosen
secondary venue). No further iteration on the formalisation is performed
before submission. Reviewer feedback may motivate revisions; pre-submission
self-review may not.

## Not in scope for this paper

The following are explicitly out of scope and may not be included:

- Probabilistic relaxations of the hierarchy
- Verified compilation of agent specifications to runtimes
- Empirical study of which levels production agent systems implicitly use
- Extensions to multi-modal or vision-language agents
- Comparison against any system that is not already publicly released

These are recorded as future work, not as future scope of this paper.

## Signatures of intent

I commit to the scope above and to revisiting this document only at the
mid-project pivot point and at submission, not in between.

[signed]