# Native Windows + Linux npm delivery work state

Branch: feat/psc1-native-npm-windows-20261031. Parent: 297081f852d7f16facc1300922d0f353c14ec3ef (PR217 native Linux G1 delivery).

User requested Windows binaries and installable native npm packages. Linux Actions only, no local builds, no force-push, no main merge, no registry publication.

## Implementation under qualification

- Reuse the exact admitted Rust G1 source from run41177075940, job124466784147, artifact13033925109, a3013ea35c48fde083f9efa0a8a4a963e6a3fcb5.
- Cross-compile that source with Rust1.90.0 and x86_64-pc-windows-gnu in Ubuntu Actions. Preserve opt-level0/256 codegen units and the 240-second tool limit. No compiler semantics changes.
- Use the qualified official Lean4.35.0 native package from run40155475188. Never reuse the historical4.34 manifest in the source checkout as4.35 evidence.
- Windows transport uses a native kill-on-close Job Object guard, creates the compiler suspended, assigns ownership before resuming, checks parent PID/creation time, and enforces the original deadline. The Linux transport remains unchanged.
- The root proofscript@0.1.0-psc1-native.1 bundles @proofscript/compiler-rust-linux-x64, @proofscript/compiler-rust-win32-x64 and exact @proofscript/pskernel-lean@4.35.0. Separate tarballs are also retained. Install scripts, automatic downloads and registry publication are disabled.
- The runtime reuses the existing checked session with fresh independent native admission, original/transformed IR checks and target validation. Windows publication selects existing portable-atomic; Linux selects portable-file.
- Installation/CLI qualification covers offline local and global npm installs, actual psc command shims, both grammars,5 executed semantic corpus programs,14 kernel fixtures, tamper/refusal/failed-publication tests. Windows additionally tests deadline, descendant and parent-exit cleanup with the real compiled supervisor.

## Honest qualification boundary

The workflow is Ubuntu-only. Windows execution uses real Windows Node/npm under Wine. Successful tests establish Windows binary compatibility under that environment, NOT a native Windows-host qualification. The published package metadata must not claim a native Windows runner result.

Both compiler and kernel are native executables. Node remains the trusted checked host. This preview exposes JS output, not all native output-target consumers. Current-source Rust G2/G3 and the240-second full-self-build target remain unqualified. No whole-compiler correctness theorem is claimed.

## Evidence

Pending the new Actions run. Do not claim package installation or Windows compatibility success until the exact-run receipts pass. Existing Linux milestone and artifact remain in PSC1_NATIVE_DELIVERY_QUALIFICATION_2026-10-31.json.
