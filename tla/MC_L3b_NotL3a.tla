---- MODULE MC_L3b_NotL3a ----
\* TLC harness: search for a Memory.tla execution where L_3a holds but
\* L_3b does not. A counter-example to the invariant L_3a => L_3b is a
\* witness for WitnessL3a_NotL3b. Run with:
\*   tlc MC_L3b_NotL3a.cfg
\* Expected: invariant violation at depth ~3, exhibiting a single
\* operation with |io|>=2 and io != co (so A_6 fires, hence ~L_3b)
\* and ExternalCells empty (so ~A_3 trivially, hence L_3a holds given
\* the read-set is empty so L_2 also holds trivially).

EXTENDS Memory, Anomalies, Levels

L3a_Implies_L3b == L3a(log) => L3b(log)

====
