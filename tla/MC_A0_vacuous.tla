---- MODULE MC_A0_vacuous ----
\* Verifies A_0 is vacuously prevented in the operational model M.
\* TLC should explore the state space and report no errors.

EXTENDS Memory, Anomalies

LostSelfWriteFree == ~LostSelfWrite(log)

====
