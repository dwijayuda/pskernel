#!/usr/bin/env python3
"""Create one diagnostic, isolated C0 variant, never modifying checked-in sources.

The ablation substitutes exactly one named implementation from the original
PSKernel-Core. It intentionally does not change tests, checker resource policy,
declaration admission, APIs or environment configuration. This is a diagnostic
comparison, not a candidate accepted production implementation.

Usage: python3 test/C0Ablation.py SRC_CORE_DIR SRC_C0_DIR
The caller must supply a private copy of the C0 package as SRC_C0_DIR.
"""
from pathlib import Path
import sys

def region(text: str, start: str, end: str) -> tuple[int, int, str]:
    if text.count(start) != 1 or text.count(end) != 1:
        raise RuntimeError(f"expected unique region delimiters: {start!r}, {end!r}")
    a, b = text.index(start), text.index(end)
    if not a < b:
        raise RuntimeError("invalid region order")
    return a, b, text[a:b]

def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: C0Ablation.py ORIGINAL_CORE COPY_OF_C0")
    original = Path(sys.argv[1]).resolve()
    variant = Path(sys.argv[2]).resolve()
    if original == variant:
        raise RuntimeError("original and temporary variant must be separate")
    file = Path("src/Ps/KernelCore/Core/Substitution/Instantiate.lean")
    old_file, variant_file = original / file, variant / file
    old_text, current_text = old_file.read_text(), variant_file.read_text()
    start = "def psKernelExprInstantiate1\n"
    end = "def psKernelExprInstantiateRev\n"
    _, _, original_fn = region(old_text, start, end)
    a, b, _ = region(current_text, start, end)
    changed = current_text[:a] + original_fn + current_text[b:]
    if changed == current_text:
        raise RuntimeError("ablation did not change the C0 implementation")
    variant_file.write_text(changed)
    print("C0_ABLATION kind=instantiate1_original source=" + str(old_file))
    print("C0_ABLATION private_target=" + str(variant_file))

if __name__ == "__main__":
    main()
