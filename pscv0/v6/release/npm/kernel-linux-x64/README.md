# PSCV V6 experimental independent kernel host

Linux x64 glibc native kernel checker built from Lean 4.35.0-rc3. Private development package, distinct from @proofscript/pskernel-lean@4.34.0 and from the small PSCV V6 compiler CLI.

This build currently supports only kernel-empty-smoke and --version; it does not accept arbitrary external admissions yet, issue PSCV-CERT, or prove .ps source fidelity. A future published provider must add canonical bounded protocol, actual acceptance tests, exact source/semantic pins, hashes, assumption restrictions, and runtime resource isolation.

Binary artifact is built by Lake in GitHub CI and packaged as npm tarball for scope-specific testing.
