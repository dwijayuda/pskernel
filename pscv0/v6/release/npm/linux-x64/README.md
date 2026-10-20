# PSCV V6 development native binary — Linux x64 glibc

This is a **private test package**, constructed from the Lean 4.35.0-rc3 sources in pscv0/v6/packages. It is not a public or complete PSCV compiler. In cloud CI, Lake builds pscv_v6_dev, copies the executable into this package bin/ directory, inspects native dependencies and creates an npm tarball. The package itself contains no JavaScript implementation or install scripts.

Before publication a matching platform compiler must have exact runtime dependency audit, reproducibility and correct checked-source/PSCV-CERT gates. The binary currently supports only --version, capabilities and kernel-empty-smoke; arbitrary .ps build/verify requests fail closed.
