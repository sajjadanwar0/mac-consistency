---- MODULE MC_A1_struct ----
EXTENDS Memory, Anomalies

L1_struct(h) ==
    \A i \in 1..Len(h) :
        \A c \in h[i].read_set :
            h[i].read_values[c] = LatestWriteBefore(h, c, h[i].read_time)

SnapshotImpliesNoStaleGen      == L1_struct(log) => ~StaleGeneration(log)
NoStaleGenerationGivenL1struct == L1_struct(log) => ~StaleGeneration(log)
NoStaleGenerationGivenL2struct == L1_struct(log) => ~StaleGeneration(log)
====
