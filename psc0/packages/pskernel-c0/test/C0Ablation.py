#!/usr/bin/env python3
"""Reproducible private C0 submodule ablations against untouched original core.

Only the requested source region/module in a copied C0 package is altered.
Checker tests, resource policies and acceptance criteria remain unchanged.

Usage: python3 C0Ablation.py ORIGINAL_CORE COPY_OF_C0 [instantiate1|environment_index]
"""
from pathlib import Path
import sys


def unique_region(text: str, start: str, end: str) -> tuple[int, int]:
    if text.count(start) != 1 or text.count(end) != 1:
        raise RuntimeError("ablation region delimiters are not unique")
    a, b = text.index(start), text.index(end)
    if a >= b:
        raise RuntimeError("ablation region order invalid")
    return a, b


def main() -> None:
    if len(sys.argv) not in (3, 4):
        raise SystemExit("usage: C0Ablation.py ORIGINAL_CORE COPY_OF_C0 [instantiate1|environment_index]")
    original = Path(sys.argv[1]).resolve()
    variant = Path(sys.argv[2]).resolve()
    kind = sys.argv[3] if len(sys.argv) == 4 else "instantiate1"
    if original == variant:
        raise RuntimeError("original and diagnostic copy must be separate")
    if kind == "instantiate1":
        file = Path("src/Ps/KernelCore/Core/Substitution/Instantiate.lean")
        old = (original / file).read_text()
        current = (variant / file).read_text()
        start = "def psKernelExprInstantiate1\n"
        end = "def psKernelExprInstantiateRev\n"
        a, b = unique_region(current, start, end)
        oa, ob = unique_region(old, start, end)
        changed = current[:a] + old[oa:ob] + current[b:]
    elif kind == "environment_index":
        file = Path("src/Ps/KernelCore/Runtime/Acceleration/EnvironmentIndex.lean")
        current = (variant / file).read_text()
        changed = (original / file).read_text()
    else:
        raise RuntimeError(f"unknown ablation kind: {kind}")
    if changed == current:
        raise RuntimeError("ablation left temporary copy unchanged")
    (variant / file).write_text(changed)
    print(f"C0_ABLATION kind={kind}_original source={original / file}")
    print(f"C0_ABLATION private_target={variant / file}")


if __name__ == "__main__":
    main()
