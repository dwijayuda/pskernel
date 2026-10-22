# Typed IO v1 scoped qualification

The source library ProofScript.System.IO defines IoRequest, IoResponse and IoError,
plus JSON request encoding and typed read/write result decoding. Both authored
grammars are exercised independently: the PS application tests put the authored
IO.ps in a local import root, so the authoritative-Lean fallback cannot silently
replace it. Source compilation still requires independent official Lean 4.35.0
admission, strict original/transformed IR and existing ordinary pairing.

The logical program produces requests and consumes responses. Effects execute
through explicitly configured Node/Python/Rust/PHP hosts and core/component
String bridges. No foreign
axiom, effectful logical evaluator or runtime fuel is introduced. This adapter
is an embedding capability boundary for generated checked programs, not a
sandbox for arbitrary JavaScript packages. Bundle metadata grants no admission.

## Portable request and response contract

Requests have exact keys:
- readLine: op
- writeLine: op,text
- readUtf8: op,path
- writeUtf8: op,path,text

Responses use kind=line,text=null|string; kind=text,text=string;
kind=unit; or kind=error,error=code. Source decoders reject malformed JSON,
wrong payload types, unexpected response kinds and unknown error codes as
protocolError. Duplicate response keys refuse through the checked JSON parser.
The host reads JSON request objects; duplicate request keys follow JSON.parse
last-value semantics, after which exact shape and capabilities are checked.
The checked source encoder emits unique request keys.

IoError codes are capabilityDenied,pathDenied,notFound,wrongType,invalidUtf8,
tooLarge,ioFailure,protocolError. Recognized OS IO failures map to ioFailure.
Programming errors, application traps, compiler/checker failures and unknown host
failures escape the source error channel.

## Linux Node provider

createTypedIo requires the exact configuration:
abi=psc1-node-linux-string-io/1; capabilities and required operation arrays;
absolute root; maxFileBytes and maxLineBytes integers in1..16777216;
and explicit inputFd/outputFd. withTypedIo performs preflight before loading the
application, closes its held root on every outcome and preserves program errors.
Missing required capabilities and unsupported ABI/configuration throw before
loading. An optional denied operation returns capabilityDenied.
No publication API is added. Existing compiler ABI/publication refusals remain.

All paths are portable relative paths with nonempty components; absolute paths,
dot/dotdot, backslash,NUL,ill-formed strings and paths over4096 UTF-8 bytes refuse.
The explicitly configured root is opened once. Descendant directories are held
with no-follow directory descriptors; operations use Linux /proc/self/fd paths.
Renaming a directory retains the opened directory capability. Symlink parents
and leaves refuse. Reads open nonblocking and require regular files, avoiding
FIFO/device hangs; size is bounded while reading, including growth after stat.
UTF-8 decoding is fatal and preserves BOM. No replacement decoding is used.

Writes reject ill-formed Unicode and oversized UTF-8 before changing the target.
They create an exclusive temporary file in the held parent, write and fsync it,
then atomically rename. Existing file content survives every refusal before
rename. Atomic replacement uses a new mode0600 inode; existing metadata/hardlink
identity is not preserved. The adapter does not claim crash-durable directory
metadata or a portable filesystem implementation.

readLine accepts LF and CRLF, preserves empty lines, returns an unterminated final
line and then EOF=null. A bare terminal CR is payload. Limits count UTF-8 payload
bytes excluding the newline; overlong input poisons further reads with tooLarge
so a truncated tail is never treated as a fresh command. Input is buffered in
4096-byte chunks. writeLine forbids embedded CR/LF, writes one LF and bounds only
payload bytes. File reads/writes preserve embedded newlines.

## Current executable acceptance

scripts/typed-io-policy-tests.mjs exercises actual Linux files/descriptors,
Unicode,BOM,CRLF,EOF,invalid encoding,byte limits,denials,traversal,symlinks,FIFO,
atomic refusal preservation and cleanup. It also runs before expensive builds
in the static Linux tier.

scripts/typed-io-application-tests.mjs independently checks and compiles
test/applications/TypedIo/Program.lean and Program.ps to JS,TS,Rust,Python,PHP. Full qualification also
executes the actual application on minimum Python. The application
reads a JSON object, transforms its text field, atomically writes canonical JSON,
and runs console echo/EOF. TS uses the pinned independent checker; Rust,Python and PHP execute
separate generated consumer processes. Expected requests agree with pinned native
Lean and final file/console bytes are independently asserted.

That original request/response application remains a regression suite using the
common Node host. General checked sequencing now executes independently through
all seven target mappings in both grammars. Each native provider passes 20 actual
Linux policy cases. The new matrix also checks source recovery, foreign trap
escape, admitted source/IR identities and ABI refusal preservation.

The typed-io family's three finite criteria and all other frozen v1 criteria
are qualified at compiler source 9ee6c5ffe8ac344b349fde7eee8f5ef867bd5dde in
[Linux run 39829564386](https://github.com/dwijayuda/pskernel/actions/runs/39829564386).
The exact complete receipt is PSC1_PRACTICAL_CORE_V1_QUALIFICATION_2026-10-23.json;
its data inventory reports 37 qualified / 0 blocked, releaseReady=true.
Pure protocol observations alone never qualify host adapters.


## Checked sequencing and standalone profiles

The checked `Io A` alias uses CompilerM with an explicit String dispatcher.
Both grammars share bind, loops, mutation, return ownership and typed handlers.
Successful external writes remain observable after later typed errors; source
handlers never convert foreign traps into IoError.

`--abi io-dispatcher` accepts a `String -> String` callback input with qualified
scalar remaining arguments/results on JS/TS/Rust/Python/PHP. Wasm's explicit
version admits Bool/String public values and refuses other shapes. The sealed manifest records publicAbi;
metadata grants no admission authority. Default ABI and verified refusals remain.

`typed_io.py` and `typed-io-rust` provide standalone Linux Python/Rust hosts.
Rust uses owned Read/Write streams and forbids unsafe code. The Linux-captured
Cargo.lock pins its dependency graph. The common 20-case actual Linux policy
matrix and general generated guest execution pass for both standalone profiles.

`typed-io.php` adds the explicit `psc1-php-linux-ffi-string-io/1` Linux CLI/glibc
profile. Enabled FFI is required before guest loading; source receives no FFI
primitive. openat and held directory descriptors enforce path policy. fstat
operates on a duplicate of a securely opened descriptor, avoiding guessed native
stat layouts. This explicit PHP profile passes Linux qualification; existing defaults retain
their boundaries. Disabled FFI refuses before root or guest access.

Earlier four-target sequencing checkpoint5a0f999a1b5d06f5b68461392fab05a8c86ca535:
https://github.com/dwijayuda/pskernel/actions/runs/39612250401
Both grammars/all seven:28 sequencing obligations, minimum Python adds4;8 actual
JS/TS/Rust/Python consumers. PHP standalone and Wasm String ABI are excluded.


Standalone Rust and PHP FFI profiles currently admit Linux x86_64, matching the
qualified system-call ABI. Other architectures refuse before source execution.
Node/Python use runtime-provided platform constants. All profiles classify
non-string paths as pathDenied and non-string text as protocolError; shared
policy tests exercise these malformed field classes.


## Preserved first seven-adapter checkpoint

Implementation 74179eb664e132502a24ce60b52a3dbd52b1d0cc, tested merge
2a6dbec7b7f3d02c6dc6399360422da350e646e7:
https://github.com/dwijayuda/pskernel/actions/runs/39627387430
The exact receipt is PSC1_TYPED_IO_EXECUTION_QUALIFICATION_2026-10-21.json.
Fourteen actual IO consumers, two minimum-Python consumers, two installed-package
consumers,80 provider policy cases and core/component String checks pass.
Wasm IO supports payload limits up to 2 MiB and a fixed 16 MiB arena; larger
configuration refuses before loading. See PSC1_WASM_STRING_ABI_V1.md.
The unpublished npm qualification package exports proofscript/io/node and
proofscript/io/wasm-core and ships the standalone Python/PHP/locked-Rust resources.
This older checkpoint does not itself establish complete release readiness.
The current finite v1 result is linked above. No registry publication has occurred.
