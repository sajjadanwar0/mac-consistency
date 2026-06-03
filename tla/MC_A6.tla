---------------------------------- MODULE MC_A6 ----------------------------------
(* Witness harness for A6 (Tool-Effect-Reordering). *)
EXTENDS Memory, Anomalies

NoToolReorder == ~ToolEffectReordering(log)
================================================================================
