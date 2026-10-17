# Phase A: checked character and string quoting

The selected implementation follows the pinned RC4 Init/Data/Repr.lean:
Char.quoteCore, Char.quote, Char.repr and String.quote. This is a shared
Standard capability required by Repr; it is not a String substitute for Std.Format.

The definitions use existing checked Bool/Nat recursors and audited Unicode
Char/String operations. String traversal has the input's UTF-8 byte count as a
derived bound: each scalar consumes at least one byte, and atEnd prevents a read
after completion. It is independent of compiler/search fuel. No new axiom,
primitive, class or instance is added. Four public definitions and one private
worker extend the selected catalogue.

Exact rules: newline and tab use named escapes; backslash and double quote
always escape; single quote escapes only outside a string; other C0 controls
and DEL use two lowercase hexadecimal digits. Unicode scalars otherwise remain
unchanged. Character results add single quotes; strings add double quotes.

Five observations cover empty input, combined escapes/control codes, non-ASCII
BMP/supplementary scalars, character quoting and the string-context distinction.
An independent native RC4 oracle checks the same values. Full existing kernel,
IR, JS/TS/Rust and GC-Wasm/component gates remain mandatory.

Implementation pending qualification and explicit review of the strict digest
change. Last qualified executable: 35e239193e69cc466b81ac57282df1b1500f4927,
Linux 38433276797, 293 observations. Repr/Std.Format, Hashable and the other
M2+A exit items remain open.

## Reviewed snapshot

At `f78c85404767c967b9baa3d019553aa1a974f73f`, Linux 38435566322 compiled
all native modules, executed the pinned quoting oracle and passed the native
signature/reducibility audit. Upstream String.Internal.append is opaque, so the
oracle compares native values rather than claiming definitional proofs.
The intentional five-definition expansion reports FNV
`fnv1a64:958383348879996756` and SHA-256
`sha256:7b6e27d14bf6d354458f01d25d4956e9bcbe03d27ba0c601129e3ec74a686356`.
The guard is repinned after review; full kernel/backend qualification follows.

## Qualification complete

Stable Lean 4.35.0, executable `0c6b7ee6896524b69858d3524356d7a30a4c7272`,
[green Linux 38437704653](https://github.com/dwijayuda/pskernel/actions/runs/38437704653):
all 298 shared observations, four panic contracts, official kernel/native oracle,
strict IR and existing JS/TS/Rust/GC-Wasm/project/component/ABI gates passed.
189 portable/197 native modules; profile /53; Standard 313/18/54.
The stable-pin digest supersedes the RC4 quoting digest recorded above:
FNV `fnv1a64:723655421381520752`, SHA-256
`sha256:41b2e17bbe8468c04e69a11df63e1656603e88ecd67b9965ffcc3e2953769e8e`.
