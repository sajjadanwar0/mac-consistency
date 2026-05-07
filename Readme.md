# mac-consistency

A formal hierarchy of memory consistency models for multi-agent LLM systems.

## What this is

Multi-agent LLM systems share state through memory stores, vector indices, and
tool registries, but no formal hierarchy of consistency models analogous to
SC/TSO/RC has been developed for this setting. This repository develops one.

The contributions, in order, are:

1. A catalogue of six consistency anomalies specific to multi-agent LLM memory
   that are not captured by classical hardware or database consistency formalisms.
2. A hierarchy of seven consistency levels that prevent successively larger
   subsets of these anomalies.
3. A mechanically verified hierarchy theorem establishing strict-stronger-than
   relationships among adjacent levels, discharged in TLAPS.
4. A reference Rust runtime implementing each admitted level, with trace-
   conformance tests against the TLA+ specifications.
5. An empirical characterisation of the latency-correctness trade-off across
   the hierarchy, on a synthetic agent workload.

## Status

In progress. Started [DATE]. See `PROTOCOL.md` for scope commitments and
stopping criteria.

## Repository layout

```
mac-consistency/
├── README.md                  # this file
├── PROTOCOL.md                # scope commitments (do not edit after week 0)
├── tla/
│   ├── Memory.tla             # abstract state machine
│   ├── Anomalies.tla          # six anomaly definitions
│   ├── Levels.tla             # seven level definitions
│   ├── Hierarchy.tla          # the hierarchy theorem
│   └── *.cfg                  # TLC configurations
├── proofs/                    # TLAPS proof obligations (week 7+)
├── rust/                      # reference runtime (week 11+)
└── eval/                      # empirical evaluation (week 15+)
```

## License

To be decided.