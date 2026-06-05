#!/usr/bin/env python3
"""
patch_allowskew.py -- add the new `AllowSkew` constant to every TLC .cfg
in the tla/ tree (including tla/matrix/), so they parse against the updated
Memory.tla.

Rule:
  AllowSkew = TRUE   for the models that must WITNESS the new A_3
                     (unsupported-read) predicate: MC_A3*, MC_A6NotA3,
                     and every matrix M_L*_CausalCascade. These need an
                     ungrounded read to be reachable.
  AllowSkew = FALSE  for everything else. With FALSE, StartRead is forced
                     to a grounded read (rv = memory) -- byte-identical to
                     the pre-change model -- so A_1/A_2/A_6 and all other
                     matrix columns are UNCHANGED.

Idempotent: skips any .cfg that already assigns AllowSkew.
Run from the tla/ directory:  python3 patch_allowskew.py
"""
import sys
from pathlib import Path


def wants_true(name: str) -> bool:
    # Models that reference CausalCascade as something to witness.
    return (name.startswith("MC_A3")
            or name == "MC_A6NotA3.cfg"
            or "_CausalCascade.cfg" in name)


def main():
    root = Path(".")
    cfgs = [p for p in root.rglob("*.cfg") if "TTrace" not in p.name]
    if not cfgs:
        sys.exit("No .cfg files found. Run this from the tla/ directory.")
    changed, skipped, true_n, false_n = 0, 0, 0, 0
    for p in sorted(cfgs):
        text = p.read_text(encoding="utf-8")
        if "AllowSkew" in text:
            skipped += 1
            continue
        val = "TRUE" if wants_true(p.name) else "FALSE"
        # Append under the CONSTANTS block (which is the last directive in
        # every cfg here). Keep a single trailing newline.
        if not text.endswith("\n"):
            text += "\n"
        text += f"    AllowSkew = {val}\n"
        p.write_text(text, encoding="utf-8")
        changed += 1
        true_n += (val == "TRUE")
        false_n += (val == "FALSE")
        print(f"  {p}  ->  AllowSkew = {val}")
    print(f"\nPatched {changed} cfg(s): {true_n} TRUE, {false_n} FALSE. "
          f"Skipped {skipped} already-patched.")
    if changed:
        print("TRUE set (A_3-witnessing models):")
        for p in sorted(cfgs):
            if wants_true(p.name):
                print(f"    {p}")


if __name__ == "__main__":
    main()
