# Typed IO v1 implementation slice

The source library ProofScript.System.IO defines IoRequest, IoResponse and IoError,
plus JSON request encoding and typed read/write result decoding. Both authored
grammars are exercised independently: the PS application tests put the authored
IO.ps in a local import root, so the authoritative-Lean fallback cannot silently
replace it. Source compilation still requires independent official Lean 4.35.0
admission, strict original/transformed IR and existing ordinary pairing.

The logical program produces requests and consumes responses. Effects execute
only through host-tools/typed-io.mjs, with explicit configuration. No foreign
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
test/applications/TypedIo/Program.lean and Program.ps to JS,TS,Rust. The application
reads a JSON object, transforms its text field, atomically writes canonical JSON,
and runs console echo/EOF. TS uses the pinned independent checker; Rust executes
a separately built generated consumer. Expected requests agree with pinned native
Lean and final file/console bytes are independently asserted.

Rust is currently a guest of the common Node capability host. Standalone Rust,
Python/PHP and Wasm IO adapters remain unfinished; Wasm public String ABI remains
an explicit blocker. The seven-target Bool protocol matrix qualifies only pure
request/response semantics, never seven host adapters or complete applications.
Release readiness must remain false until all fixed contract criteria qualify.
