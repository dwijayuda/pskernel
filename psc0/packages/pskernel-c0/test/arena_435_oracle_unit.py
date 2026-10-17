#!/usr/bin/env python3
"""Strict unit tests for the official pinned 4.35 oracle's outcome parser."""
from arena_lean435_compat import parse_official_reference_result as check

def main():
    yes="Lean default kernel accepts the solution\n"
    no="Lean default kernel rejects the solution\n"
    duplicate="uncaught exception: Duplicate declaration: dup_defs\n"
    assert check(yes,0)["verdict"]=="accepted"
    assert check(no,1)["verdict"]=="rejected"
    accepted=check(duplicate,1)
    assert accepted["verdict"]=="rejected"
    assert accepted["reason"]=="official_kernel_duplicate_declaration"
    for out,code in [(duplicate,0),(duplicate+"unrelated failure\n",1),
                     ("uncaught exception: File access error\n",1),
                     ("uncaught exception: Duplicate declaration:\n",1),
                     ("uncaught exception: Duplicate declaration: a b\n",1),
                     (yes,1),(no,0),(yes+no,1)]:
        assert check(out,code)["verdict"]=="driver_error",(out,code)
    print("C0_ARENA_435_OFFICIAL_ORACLE exact_duplicate_kernel_rejection=pass arbitrary_exception_cannot_reject=pass")

if __name__=="__main__":
    main()
