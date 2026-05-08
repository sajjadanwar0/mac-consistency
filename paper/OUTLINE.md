# A Formal Hierarchy of Memory Consistency Models for Multi-Agent LLM Systems

**Target venue:** Transactions on Machine Learning Research (TMLR)
**Status:** Draft outline
**Author:** [your name]

---

## Abstract (≈250 words)

Multi-agent systems built on large language models share state through memory
stores, vector indices, and tool registries. The concurrency patterns these
systems exhibit — long-running operations whose duration is dominated by
neural inference, write sets that emerge during execution rather than being
declared in advance, and tool calls with irreversible external effects — fall
outside the regimes addressed by classical hardware consistency models
(SC/TSO/RC) and database isolation theory (read-committed, snapshot
isolation, serialisability). A March 2026 SIGARCH position paper identifies
multi-agent memory consistency as the most pressing open formal problem in
agentic AI infrastructure, noting that no analogue of the classical
consistency hierarchy yet exists for this setting.

This paper develops such a hierarchy. We catalogue six consistency anomalies
specific to multi-agent LLM memory and define seven consistency levels that
prevent successively larger subsets of these anomalies. Each anomaly is
TLC-verified by an explicit counter-example witness; the hierarchy theorem
establishing strict-stronger-than relationships among adjacent levels is
mechanically proved in TLAPS. The construction reveals a result analogous
to the classical write-skew limitation of database snapshot isolation:
generation snapshot consistency is insufficient to prevent stale-generation
anomalies and must be augmented with explicit read-set stability.

The contribution is foundational rather than empirical: we provide the
vocabulary practitioners need to specify consistency requirements for
multi-agent LLM systems and the formal framework against which runtime
implementations can be verified. A reference Rust implementation is
deferred to a follow-up paper.

**Keywords:** multi-agent systems, memory consistency, isolation levels,
formal methods, TLA+, large language models.

---

## 1. Introduction (≈800 words)

### 1.1 The problem

[Open with a concrete example: two LLM agents sharing a knowledge base,
showing where things go subtly wrong. Make it visceral.]

### 1.2 Why classical consistency theory does not transfer

[Three short paragraphs:]

- Hardware models (SC, TSO, ARMv8) assume bounded operation latency and
  statically-known read/write sets. Neither holds for agents.
- Database isolation theory (Berenson 1995, Adya 1999) assumes explicit
  transaction boundaries and synchronous tool effects. Agents have neither.
- Existing systems work (Atomix, SagaLLM, CodeCRDT) addresses single
  consistency points, not a hierarchy.

### 1.3 The SIGARCH gap

[Cite the March 2026 position paper: no formal hierarchy of consistency
models for agent memory exists. This is the open problem.]

### 1.4 Contributions

We make four contributions:

1. A catalogue of six consistency anomalies specific to multi-agent LLM
   memory, with TLC-verified witness traces (Section 3).
2. A hierarchy of seven consistency levels that prevent successively larger
   subsets of anomalies (Section 4).
3. A mechanically verified hierarchy theorem (Section 5), comprising 21
   TLAPS-discharged proof obligations.
4. A clarifying observation that generation snapshot consistency is
   insufficient to prevent stale-generation, generalising the classical
   write-skew result of Berenson et al. to the agent setting (Section 4.4).

### 1.5 Roadmap

[One paragraph describing the rest of the paper.]

---

## 2. Background (≈600 words)

### 2.1 Hardware consistency models

[Brief recap. Cite Lamport 1979 (SC), Sindhu et al. 1992 (TSO),
Gharachorloo et al. 1990 (RC), Pulte et al. 2018 (ARMv8).]

### 2.2 Database isolation hierarchy

[Recap with focus on Adya's (1999) approach: anomaly-based level
characterisation, separation of specification from implementation. This is
the conceptual model we follow.]

### 2.3 Multi-agent LLM systems

[Brief description of the runtime model: agents, shared memory, tool
registries, generation phases, externalised effects. Be concrete enough
that a non-AI reader understands what's at stake.]

### 2.4 Existing infrastructure work

[Survey: Atomix (transactional tool calls), SagaLLM (Saga compensation),
CodeCRDT (CRDTs for code generation), FIDES/SAFEFLOW (information flow),
TACIT/Turn (capability types), Cemri et al.'s MAST taxonomy (NeurIPS 2025
failure modes).]

### 2.5 The gap

[Restate the SIGARCH observation: no hierarchy exists. This paper supplies
one.]

---

## 3. Consistency Anomalies (≈1200 words)

### 3.1 Model and notation

[Introduce the abstract operation model: each operation has a Read phase, a
Generate phase, and a Write phase. The Generate phase has unbounded
duration. Operations have read_set, read_values, read_time, write_set,
write_values, write_time, plus auxiliary fields for tool registries and
externalisation. Reference Memory.tla in the artifact.]

### 3.2 The six anomalies

For each of A1 through A6:

- **Definition** (formal, in prose with mathematical notation)
- **Informal description** (a paragraph of plain English)
- **Witness** (refer to TLC trace in artifact, summarise key states)
- **Why classical models miss it** (one sentence each)

#### 3.2.1 A1 (Stale-Generation)

[Concrete: agent reads memory, another agent writes during the long
generation phase, agent commits a value that no longer reflects reality.]

#### 3.2.2 A2 (Phantom-Tool)

[Tool registry mutates between an agent's planning step and execution.]

#### 3.2.3 A3 (Causal-Cascade)

[An external commit is later undermined by a write that retracts its read
context — the external effect persists with no current grounding.]

#### 3.2.4 A4 (Split-View) [DEFERRED]

[Note that this anomaly requires a replication model and is not formalised
in this paper. Treated in future work; current hierarchy admits it
trivially.]

#### 3.2.5 A5 (Long-Generation Window)

[Strictly stronger than A1: multiple intervening writes during one
generation. Captures the cumulative effect of a long-running prefill/decode
window.]

#### 3.2.6 A6 (Tool-Effect Reordering)

[Within a single operation, tool effects externalise in an order
inconsistent with their issuance order.]

### 3.3 Empirical verification

[Each anomaly has a TLC-verified witness in the artifact. State
configuration, witness depth, and link to MC_A<j>_witness.txt.]

---

## 4. The Consistency Hierarchy (≈1000 words)

### 4.1 Construction principle

[Following Adya (1999), each level is characterised by the anomalies it
prevents. Higher levels prevent strictly more anomalies. The structural
implementation strategy (snapshot, locks, OCC, MVCC) is orthogonal to the
specification.]

### 4.2 The seven levels

[For each of L0 through L6, a formal definition (the TLA+ predicate from
Levels.tla) and a paragraph of motivation.]

### 4.3 The hierarchy table

[Reproduce HIERARCHY_MATRIX.md as Table 1, with discussion of which
empirical cells are verified by TLC witness traces and which prevention
relations follow from the level definitions.]

### 4.4 The snapshot-insufficiency observation

[This is one of the contribution claims. Show explicitly that defining L2
purely as "read_values reflect memory at read_time" — the natural
structural definition of generation snapshot consistency — does NOT
prevent A1. The proof is by the same kind of write-skew argument that
shows snapshot isolation does not prevent lost updates in databases. To
prevent A1, the level must additionally enforce that no write to the
read-set occurs during the generation window.]

### 4.5 Why L4 and L5 collapse without A4

[Explain the L4 = L5 collapse honestly: A4 is currently FALSE in our
model, so the level distinguished by ~A4 collapses into the level below.
The distinction becomes meaningful when replication is added, which is
discussed in Section 7.]

---

## 5. Hierarchy Theorem and Mechanical Verification (≈800 words)

### 5.1 Statement

**Theorem 1 (Hierarchy).** For every adjacent pair of levels (L_i, L_{i+1}),
L_{i+1}(h) ⇒ L_i(h) for all histories h ∈ Seq(OpRecord).

[Statement in TLA+ syntax with cross-reference to the Hierarchy.tla module.]

### 5.2 Proof structure

[The proof is decomposed into 21 TLAPS-discharged obligations:]

- Six containment theorems (L_{i+1} ⇒ L_i for each i ∈ {0,...,5})
- Fourteen transitive soundness theorems (L_i prevents anomalies prevented
  by all weaker levels)
- One aggregate theorem combining the above

[Each individual obligation is a definition-expansion application of
conjunction elimination. The TLAPS proof script is in proofs/Hierarchy.tla
in the artifact.]

### 5.3 Direct soundness claims as definitional consequences

[Six "direct" prevention claims (L_2 prevents A_1, etc.) are tautologies
of the level definitions and not stated as separate theorems. By
construction, L_2(h) ≡ ~A_1(h) ∧ ~A_5(h), so L_2(h) ⇒ ~A_1(h) holds by
∧-elimination. The transitive theorems carry the substantive content.]

### 5.4 Limits of the mechanical verification

[Acknowledge: the TLC empirical matrix exhausts at MaxOps=2 with the full
constants. We verify the "admits" claims via explicit witness traces and
the "prevents" claims via the construction of level definitions plus
TLAPS proofs. The full empirical (level × anomaly) matrix at MaxOps≥3 is
intractable for our model size. This is a tooling limitation, not a
substantive gap.]

---

## 6. Discussion (≈800 words)

### 6.1 Connection to classical results

- A1 prevention requires what amounts to read-set stability — analogous
  to repeatable-read in databases.
- A6 prevention requires atomic externalisation — analogous to
  one-shot transactional commit.
- A2 prevention requires registry stability across the operation lifetime
  — analogous to predicate locking against phantoms.

### 6.2 What practitioners can do today

[A short table mapping common system designs to the level they implement:
- Vanilla key-value store: L0
- Session-consistent KV: L1
- Snapshot KV with read-time consistency: L2 partial (admits A1)
- OCC with abort-on-conflict: L4 or L5
- Two-phase commit + serial scheduler: L6]

### 6.3 Limitations

- A4 (Split-View) is deferred to follow-up work
- The Rust reference implementation is deferred to follow-up work
- Empirical performance trade-offs are deferred to follow-up work
- The model assumes operations have well-defined read/write phases; some
  agent runtimes interleave reads with generation in ways our model
  abstracts over

### 6.4 Future work

[This is the thesis programme. Three or four planned follow-ups:]

- Reference runtime in Rust with trace-conformance testing against the
  TLA+ specification
- Probabilistic relaxations of the hierarchy that account for LLM
  stochasticity
- Replication model and A4 (Split-View) anomaly
- Empirical study of which levels existing production agent systems
  implicitly implement

---

## 7. Related Work (≈400 words)

[Brief, focused. Group into: classical hardware consistency, database
isolation theory, recent multi-agent infrastructure systems (Atomix,
SagaLLM, CodeCRDT), and the SIGARCH position paper that motivates this
work. Do not over-cite — TMLR rewards focus.]

---

## 8. Conclusion (≈200 words)

[Restate the contribution: a formal hierarchy where none existed before,
with mechanically verified soundness theorems and TLC-verified anomaly
witnesses. The hierarchy gives practitioners a precise vocabulary and
researchers a foundation to build on.]

---

## A. Reproducibility statement

[Required by TMLR. Repository link: https://github.com/<your-handle>/mac-consistency
Specifies TLA+ tools version (2026.04.09), TLAPS revision (fd3988f),
and gives instructions to reproduce all 5 anomaly witnesses and 21
TLAPS theorems from the published artifact.]

## B. Author contributions

[Single author: all contributions.]

---

## Word budget summary

| Section | Target |
|---------|--------|
| Abstract | 250 |
| Intro | 800 |
| Background | 600 |
| Anomalies | 1200 |
| Hierarchy | 1000 |
| Theorems | 800 |
| Discussion | 800 |
| Related work | 400 |
| Conclusion | 200 |
| **Total body** | **~6,000** |

TMLR has no hard length limit but expects "appropriate length for the
contribution". 6,000 words plus an artifact appendix is well within norms
for a formal-methods paper.

---

## Writing strategy and order

Don't write top-to-bottom. Write in this order to minimise revision:

1. **Section 3 (Anomalies)** — most concrete, reuses your TLC work directly.
   Start here. The traces are already done; you're just narrating them.

2. **Section 4 (Hierarchy)** — formal definitions are already in
   Levels.tla. Write motivation paragraphs around them.

3. **Section 5 (Theorem)** — the TLAPS module is already done. Section 5
   is mostly description of what the module proves.

4. **Section 6 (Discussion)** — the contribution becomes clear after
   Sections 3-5 are written. Easy to write at this point.

5. **Section 2 (Background)** — write last among the body sections so
   you cite only what you actually depend on. Keep it tight.

6. **Section 1 (Introduction)** — write absolute last. The introduction
   sells what's already written; trying to write it first leads to
   over-promising and revision pain.

7. **Section 7 (Related Work)** — last, after intro. Easy to compile.

8. **Abstract** — write after the introduction is final. Distil from
   intro.

Aim for 2,000 words per week of writing. Six weeks gets you to
submission-ready. Add two weeks for cold-read review and revision.

---

## Hard scope rules

To prevent the S-Bus v29-v54 pattern:

- **No new theorems.** The current 21 TLAPS theorems and the 5 TLC
  witnesses are the contribution. Do not add a 6th anomaly. Do not
  attempt to mechanise the direct soundness theorems.

- **No new sections.** The 8 sections plus 2 appendices above are the
  paper's structure. Do not add a "Section 9: Probabilistic Extensions" —
  that's paper #2.

- **No new related work after the first draft.** When reviewers cite
  papers you missed, add them in the revision. Do not preemptively cover
  everything in the literature.

- **One cold-read review pass before submission.** Not three. Pick the
  most thorough reviewer, give them the manuscript and a deadline.