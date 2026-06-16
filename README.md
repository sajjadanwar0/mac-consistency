# Verified Detection and Prevention of Concurrency Anomalies in Multi-Agent LLM Systems — Artifact

This artifact accompanies the paper *Verified Detection and Prevention of
Concurrency Anomalies in Multi-Agent Large Language Model Systems*
(arXiv:2606.xxxxx). It comprises three repositories:

| Repository | Contents |
|---|---|
| `mac-consistency` (this repo) | TLA+ specifications, TLC model configs, TLAPS proofs, and the LaTeX source (`mac-consistency.tex`) |
| `mac-consistency-runtime` | Executable Rust runtime (the L0–L4 backends, the four detector ports, and the live-agent `l2-live/` driver), plus two Verus-exec helpers (`verified_si.rs`, `lib_si_validate_exec.rs`) |
| `mac-consistency-pilot` | The full Verus development (`verus-detector/`, 27 proof files, 274 curated / 295 full obligations) and the empirical Python harnesses |

The consistency lattice is the linear chain **L0 ⊂ L1 ⊂ L2 ⊂ L3 ⊂ L4**
over four formalized anomalies:

| Level | Adds exclusion of | Anomaly |
|---|---|---|
| L0 | — (admits everything) | — |
| L1 | `StaleGenerationFree` | A₁ stale generation |
| L2 | `CausalCascadeFree` | A₃ causal cascade (unsupported read) |
| L3 | `ToolEffectReorderingFree` | A₆ tool-effect reordering |
| L4 | `PhantomToolFree` | A₂ phantom tool |

---

## Prerequisites

- **TLC / SANY / TLAPS** via `tla2tools.jar` (TLC) and `tlapm` (TLAPS).
  We invoke TLC as `tlc -config MODEL.cfg MODEL.tla`
  (alias: `tlc="java -cp $HOME/tla2tools.jar tlc2.TLC"`).
- **Verus** (main-branch build) and a recent **Rust** toolchain (`cargo`)
  for the proofs/runtime in the other two repositories.
- Python 3 (stdlib only) for the empirical harnesses (`mac-consistency-pilot`).

---

## Repository layout

```
tla/                 TLC model checking: Memory.tla, Anomalies.tla, Levels.tla,
                     the MC_* anomaly/incomparability/struct witnesses, CodeCRDT.tla,
                     and matrix/ (TLAPS proofs + the L0–L4 realizability matrix).
tla/matrix/          Hierarchy.tla, A1LowerBound.tla (the verified TLAPS proofs),
                     M_L{0..4}_{StaleGeneration,CausalCascade,ToolEffectReordering,PhantomTool}
                     realizability models, and the OMITTED design skeletons.
proofs/              Legacy duplicate of the proof files, retained only for the
                     recorded TLAPS run logs (tlapm_output.txt, tlaps_output.txt).
                     Not canonical; prefer tla/matrix/. (Slated for removal.)
mac-consistency.tex  LaTeX source of the paper.
```

---

## A. TLC model checking (`tla/`)

Models fall into three reproduction classes. A run-all harness **must**
classify them accordingly — a non-zero "invariant violated" exit is a
*pass* for an expect-violation model.

### A.1 Expect-violation (TLC reports `Invariant ... is violated`, exit 12)

These exhibit an anomaly by design; the violation trace **is** the result.

- Anomaly witnesses: `MC_A1`, `MC_A2`, `MC_A3`, `MC_A6`
  (and `_medium` / `_large` bound variants).
- Lattice incomparability: `MC_A3NotA6`, `MC_A6NotA3`
  (A₃ and A₆ are mutually incomparable).
- Snapshot insufficiency: `MC_A1_struct{,_medium,_large}`
  (a per-read snapshot discipline does **not** prevent stale generation;
  this is the Section 4.3/4.4 demonstration).

### A.2 Expect-hold (TLC reports `No error has been found`)

- `MC_A0_vacuous` — vacuity check.
- Realizability matrix `matrix/M_L{0..4}_{StaleGeneration,CausalCascade,ToolEffectReordering,PhantomTool}`.
  Each `M_Ln_X` checks whether level `Ln` excludes anomaly `X`. Expected
  pattern (a level excludes an anomaly iff the anomaly's `*Free` conjunct
  is at or below it):

  | Anomaly | violates (admits) | holds (excludes) |
    |---|---|---|
  | `StaleGeneration` (A₁) | L0 | L1 L2 L3 L4 |
  | `CausalCascade` (A₃) | L0 L1 | L2 L3 L4 |
  | `ToolEffectReordering` (A₆) | L0 L1 L2 | L3 L4 |
  | `PhantomTool` (A₂) | L0 L1 L2 L3 | L4 |

- `MC_CodeCRDT_RYW` — read-your-writes / `LostSelfWriteFree`. The
  **baseline** (`|A|=2`, `MaxOps=3`) is **exhaustive**: 9,348,770 distinct
  states, depth 12, no violation. The `_medium` (`|A|=3`, `MaxOps=6`) and
  `_large` (`|A|=3`, `MaxOps=9`) runs are **bounded partial explorations**
  (in excess of 150 million distinct states each, no violation found within
  a 10-minute budget) — *not* exhaustive checks.

`MC_CodeCRDT_AdmitsA1` is expect-violation (CodeCRDT admits A₁; this places
it at L₁-but-not-L₂ together with the RYW vacuity above).

### A.3 The `AllowSkew` constant

`Memory.tla` declares `CONSTANT AllowSkew`. `AllowSkew = TRUE` permits an
ungrounded read, which is how the A₃ unsupported-read footprint is
witnessed in the model. Configs set it as a standalone `CONSTANT AllowSkew = ...`
line:

- **TRUE** for the A₃-witnessing models: `MC_A3*`, `MC_A6NotA3`,
  `matrix/M_L*_CausalCascade`.
- **FALSE** for all other Memory-extending models (grounded reads).

`CodeCRDT.tla` does **not** extend `Memory`; it `INSTANCE`s it with
`AllowSkew <- TRUE` (the relaxed, staleness-permitting refinement target).
The `MC_CodeCRDT_*` configs therefore carry **no** `AllowSkew` line.

---

## B. TLAPS proofs (`tla/matrix/`)

### Verified (machine-checked, no `assume`/`omitted`)

```bash
cd tla
tlapm matrix/Hierarchy.tla      # 15 obligations — chain coherence (L0..L4)
tlapm matrix/A1LowerBound.tla   # 28 obligations — Theorem 5.1 (A1 generation lower bound)
```

`Hierarchy.tla` states **11 theorems** — four adjacent-pair containments
(`L1_Implies_L0` … `L4_Implies_L3`), six transitive prevention results
(`L2_Prevents_A1`, `L3_Prevents_A1`, `L3_Prevents_A3`, `L4_Prevents_A1`,
`L4_Prevents_A3`, `L4_Prevents_A6`), and the aggregate `ChainCoherence` —
which TLAPS decomposes into **15** atomic proof obligations (see
`proofs/tlapm_output.txt`: *All 15 obligations proved*).

`A1LowerBound` proves the generation-phase lower bound under two
well-formedness hypotheses, each a `Memory.Spec` invariant lifted to the
trace level: `NonOverlappingAgent` (history-level `inv-OneInFlight`) and
`MonotonicOp` (`read_time <= write_time` per operation). TLAPS reports
**28** obligations proved (`proofs/tlaps_output.txt`).

### Design skeletons (proofs `OMITTED` — NOT verified, excluded from the verified set)

- `matrix/Refinement.tla` — CodeCRDT → relaxed-`Memory` refinement. All
  action-refinement steps are `OMITTED`; the file is documentation of the
  intended simulation only. (It does not elaborate under the current TLAPS
  because the projection references the `RECURSIVE` `ApplyForward` operator
  through an instance substitution.) **CodeCRDT's L₁/¬L₂ placement is
  established by the TLC harnesses above, not by this file.**
- `matrix/CompletenessProof.tla` — `OMITTED` skeleton.

Do **not** include `Refinement.tla`, `CompletenessProof.tla`, or the TLC
spec modules (`CodeCRDT.tla`, `Memory.tla`, `Anomalies.tla`) in a
"run-all-proofs" `tlapm` pass; they are not proof targets.

---

## C. Verus proofs and the executable runtime (other repositories)

The Verus development lives in `mac-consistency-pilot`; the executable
runtime in `mac-consistency-runtime`.

```bash
# Detector equivalence (sound + complete for all four detectors)
cd ../mac-consistency-pilot/verus-detector
verus src/lib_detector_equivalence.rs        # 24 verified, 0 errors

# Runtime L2 safety proof (transitive cascade + non-vacuity witness)
verus src/lib_l2_safety.rs                   # 22 verified, 0 errors

# Full obligation count (curated headline = 274; --full = 295 distinct)
cd ..
./verus_count.sh           # curated total
./verus_count.sh --full    # full distinct total

# Executable runtime + end-to-end tests
cd ../mac-consistency-runtime
cargo build && cargo test                    # integration + in-module tests pass
```

The detector's `a3_witness` is the same unsupported-read predicate as
`Anomalies.tla`'s `CausalCascade` and the runtime state-view, so the A₃
definition is consistent across prose, TLA+ model, TLC witness, Verus
detector, and runtime.

---

## Verification status summary

| Component | Status |
|---|---|
| A₃ closure (prose / TLA+ / TLC witness / Verus detector / runtime / hierarchy) | consistent, verified |
| `tla/matrix/Hierarchy.tla` | 15 obligations proved |
| `tla/matrix/A1LowerBound.tla` | 28 obligations proved |
| TLC anomaly / incomparability / matrix / struct models | reproduce as classified above |
| `MC_CodeCRDT_RYW` baseline (`MaxOps=3`) | exhaustive, 9,348,770 states, no violation |
| `MC_CodeCRDT_RYW` medium/large | bounded partial, no violation within budget |
| Verus detector equivalence / runtime L2 safety | verified (24 / 22) — see `mac-consistency-pilot` |
| Full Verus obligation count | 274 curated / 295 full (`verus_count.sh`) |
| `matrix/Refinement.tla`, `matrix/CompletenessProof.tla` | `OMITTED` design skeletons |

---

## Notes

- Agent-symmetry reduction was evaluated for the CodeCRDT runs but yields
  only ~2× here (per-agent `syncClock` makes most states permutation-
  distinct), so it is **not** used; the baseline is exhaustive without it.
- The lattice is the linear L0–L4 chain. The abandoned split-scheme files
  (`Incomparability.tla`, `matrix/M_L5_*`, `matrix/M_L6_*`, `MC_L3a_NotL3b*`,
  `MC_L3b_NotL3a*`) have been removed from `tla/`. **Note:** a stale
  `proofs/Incomparability.tla` and the rest of the `proofs/` duplicate are
  still present; `proofs/` is retained only for the recorded TLAPS logs and
  is otherwise superseded by `tla/matrix/`.
- Generated artifacts (`*_TTrace_*`, `.tlacache/`, Rust `target/`) are
  git-ignored.