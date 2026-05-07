--------------------------------- MODULE Levels --------------------------------
EXTENDS Memory, Anomalies

\* L0. Eventually Visible
L0(history) == TRUE

\* L1. Per-Agent Read-Your-Writes
L1(history) ==
    \A i \in 1..Len(history) :
        \A c \in history[i].read_set :
            LET prior_self_writes ==
                  { j \in 1..(i-1) :
                      /\ history[j].agent = history[i].agent
                      /\ c \in history[j].write_set }
            IN  prior_self_writes = {} \/
                LET latest == CHOOSE j \in prior_self_writes :
                                \A k \in prior_self_writes :
                                    history[k].write_time =< history[j].write_time
                IN history[i].read_time >= history[latest].write_time

\* L2. Generation Snapshot
L2(history) ==
    \A i \in 1..Len(history) :
        \A c \in history[i].read_set :
            history[i].read_values[c] =
                LET prior_writes ==
                      { j \in 1..Len(history) :
                          /\ c \in history[j].write_set
                          /\ history[j].write_time =< history[i].read_time }
                IN  IF prior_writes = {} THEN NULL
                    ELSE LET latest == CHOOSE j \in prior_writes :
                                         \A k \in prior_writes :
                                             history[k].write_time =< history[j].write_time
                         IN history[latest].write_values[c]

\* L3-L6 (TODO Week 3)
L3(history) == TRUE
L4(history) == TRUE
L5(history) == TRUE
L6(history) == TRUE

\* Soundness sanity check
L2_PreventsA1 ==
    \A history \in Seq(OpRecord) :
        L2(history) => ~StaleGeneration(history)

================================================================================
