---- MODULE MC_A1_struct ----
EXTENDS Memory, Anomalies

\* Structural snapshot predicate (paper §4.4).
\* Reads must equal the latest write to each cell before the read time.
L1_struct(h) ==
    \A i \in 1..Len(h) :
        \A c \in h[i].read_set :
            h[i].read_values[c] = LatestWriteBefore(h, c, h[i].read_time)

\* Invariant TLC will violate, demonstrating snapshot insufficiency.
\* Three aliases so any cfg (legacy or new) finds a defined invariant.
SnapshotImpliesNoStaleGen      == L1_struct(log) => ~StaleGeneration(log)
NoStaleGenerationGivenL1struct == L1_struct(log) => ~StaleGeneration(log)
NoStaleGenerationGivenL2struct == L1_struct(log) => ~StaleGeneration(log)
====
