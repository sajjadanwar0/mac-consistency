-------------------------- MODULE A3_witness_check --------------------------

EXTENDS Naturals, Sequences

NULL == "NULL"

CausalCascade(h) ==
    \E j \in 1..Len(h), p \in 1..Len(h) :
        /\ ~ h[j].aborted
        /\ p \in h[j].preds
        /\ h[p].aborted

CausalCascadeResidue(h) ==
    \E j \in 1..Len(h) :
        \E c \in DOMAIN h[j].read_values :
            /\ c \in h[j].read_set
            /\ h[j].read_values[c] # NULL
            /\ \A k \in 1..Len(h) :
                 (k # j) =>
                   ~ ( /\ c \in h[k].write_set
                       /\ h[k].write_time =< h[j].read_time
                       /\ h[k].write_values[c] = h[j].read_values[c] )

h_cascade ==
  << [ aborted      |-> TRUE,
       preds        |-> {},
       read_set     |-> {},
       read_time    |-> 0,
       read_values  |-> << >>,
       write_set    |-> {"c1"},
       write_time   |-> 1,
       write_values |-> [x \in {"c1"} |-> "v1"] ],
     [ aborted      |-> FALSE,
       preds        |-> {1},
       read_set     |-> {"c1"},
       read_time    |-> 1,
       read_values  |-> [x \in {"c1"} |-> "v1"],
       write_set    |-> {},
       write_time   |-> 2,
       write_values |-> << >> ] >>

h_benign ==
  << [ aborted      |-> FALSE,
       preds        |-> {},
       read_set     |-> {"c1"},
       read_time    |-> 1,
       read_values  |-> [x \in {"c1"} |-> "v1"],
       write_set    |-> {},
       write_time   |-> 1,
       write_values |-> << >> ] >>

VARIABLE dummy
Init == dummy = 0
Next == dummy' = dummy
Spec == Init /\ [][Next]_dummy

Result ==
    /\ CausalCascade(h_cascade)
    /\ ~ CausalCascade(h_benign)
    /\ CausalCascadeResidue(h_benign)
=============================================================================
