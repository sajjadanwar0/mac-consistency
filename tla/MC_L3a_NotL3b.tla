---- MODULE MC_L3a_NotL3b ----
\* TLC harness: search for a Memory.tla execution where L_3b holds but
\* L_3a does not. A counter-example to the invariant L_3b => L_3a is
\* a witness for WitnessL3b_NotL3a. Run with:
\*   tlc MC_L3a_NotL3b.cfg
\* Expected: invariant violation at depth ~5, exhibiting an operation
\* with |io|<=1 (so ~A_6, hence not blocked from L_3b) and an external
\* commit followed by a read-set contradiction (so A_3 fires, hence
\* ~L_3a).

EXTENDS Memory, Anomalies, Levels

\* The negation of the implication L_3b => L_3a, expressed as an
\* invariant. TLC finds a state violating this invariant; that state's
\* log is the witness h_1 of WitnessL3b_NotL3a.
L3b_Implies_L3a == L3b(log) => L3a(log)

====
