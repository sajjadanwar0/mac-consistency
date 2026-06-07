-------------------------- MODULE A3_witness_check --------------------------
(***************************************************************************)
(* Standalone TLC harness for the Option-A A_3 redefinition.               *)
(*                                                                         *)
(* Run:   tlc A3_witness_check        (with A3_witness_check.cfg)           *)
(*   where  tlc = java -cp $HOME/tla2tools.jar tlc2.TLC                     *)
(*                                                                         *)
(* PASS condition: the invariant Result holds (TLC reports no error).      *)
(* That single green check confirms three facts simultaneously:            *)
(*   (1) the new CausalCascade FIRES on a genuine cascade witness;         *)
(*   (2) it does NOT fire on a benign serial history (the Option-A fix);   *)
(*   (3) the OLD residue predicate DID fire on that benign history         *)
(*       (the over-approximation bug the redefinition removes).            *)
(***************************************************************************)
EXTENDS Naturals, Sequences

NULL == "NULL"

(* --- the two predicates, inlined so this module is self-contained --- *)
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

(* --- WITNESS 1: a genuine uncompensated cascade ---                       *)
(*   op1 writes c1=v1 then ABORTS;  op2 reads c1=v1, has 1 in preds, COMMITS *)
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

(* --- BENIGN serial history: op reads an initial/seeded value c1=v1 that   *)
(*     no logged op wrote, and NOTHING aborts. Old residue fires; new A_3    *)
(*     must not. ---                                                        *)
h_benign ==
  << [ aborted      |-> FALSE,
       preds        |-> {},
       read_set     |-> {"c1"},
       read_time    |-> 1,
       read_values  |-> [x \in {"c1"} |-> "v1"],
       write_set    |-> {},
       write_time   |-> 1,
       write_values |-> << >> ] >>

(* --- trivial one-state spec so TLC has something to run --- *)
VARIABLE dummy
Init == dummy = 0
Next == dummy' = dummy
Spec == Init /\ [][Next]_dummy

Result ==
    /\ CausalCascade(h_cascade)          \* (1) cascade fires
    /\ ~ CausalCascade(h_benign)         \* (2) benign does NOT fire new A_3
    /\ CausalCascadeResidue(h_benign)    \* (3) benign DID fire old residue
=============================================================================
