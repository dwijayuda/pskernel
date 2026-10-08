# PSC0 — compiler and kernel self-host status

Status date: 2026-10-09. The active, single TypeScript-to-JavaScript
toolchain is **TypeScript 7.0.2** (native Go compiler). Its CLI is version
checked before any executable emission and runs with strict ES2022 ESM,
declarations, source maps, noEmitOnError, and --ignoreConfig.

## Kernel-checked compiler and source baseline

The compiler-only source closure remains 55 unchanged PSC1-portable modules,
with canonical source closure SHA-256
`ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7`.
The compiler's generated TypeScript fixed-point source SHA-256 was
`fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033`.
A previous full native-PSKernel-Core checked compiler-only fixed-point
certification passed: GitHub Actions #37825822957.

**Toolchain upgrade note:** that previous success is historical evidence.
A new TS7-generated JavaScript fixed-point digest must be independently
measured and certified. Do not use the old JavaScript hash as current TS7
emission evidence. Only TS7 is supported for new PSC0 TypeScript/JS builds.

## Joint self-host and portability

PSKernel Core's separate 79-module executable implementation closure
excludes proof/metatheory, and passes PSC1 source checks. Native PSC0
generated a runnable JS kernel in GitHub Actions #37834917811.

The full compiler plus generated-kernel checking/fixed point is **NOT YET
CERTIFIED**. PR #85 owns this work. The TS7 toolchain migration changes
only the compiler/frontend host scripts and artifacts, not the 55 portable
semantic source modules nor the standalone metatheory/proofs. Checked
receipts identify the TS7 CLI toolchain, and cached older receipts do not
authorize a new build.

## Toolchain evidence

The experimentally checked 79-module kernel TypeScript corpus (4,229,736
bytes) passed TypeScript 7.0.2 strict checking, declarations, emission,
and independent JS kernel runtime smoke in 23.279 seconds with 439,588 KiB
peak resident memory. See Actions #37851336504 and PR #86. This is a
single real workload, not complete compiler+kernel bootstrap evidence.

Production release and npm distribution remain blocked on their own
kernel assurance and current TS7 fixed-point acceptance gates.
