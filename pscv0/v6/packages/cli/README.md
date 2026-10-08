# @proofscript/pscv-cli — Lean-native development CLI

Implementation: [src/PscvDevMain.lean](src/PscvDevMain.lean), built into Lake native executable pscv_v6_dev. Commands: --version, capabilities, core-smoke. The large Lean Environment/kernel checking code is **not linked** into the compiler CLI; it is built separately as pscv_v6_kernel_dev. Unsupported build/verification options exit nonzero.

This is a development compiler interface, not the final psc release. npm metadata packages Lean sources; platform-specific native binaries and optional thin launchers will follow. There is no authored JavaScript compiler CLI.
