# Streaming compiler application v1

This application reads an actual UTF8 source file, scans decimal-number and
addition/separator tokens, parses statements, constructs add expression nodes,
constant-folds them and renders an exact JSON program summary. It is an
acceptance application, not PSC1 compiler self-hosting.

The finite grammar is `Nat + Nat ;` repeated with ASCII space/tab/CR/LF between
tokens. Multi-digit and arbitrary-precision Nat literals use existing exact
arithmetic. Empty input is valid. The summary contains statement count and total
folded value, with canonical JSON key order. Streaming folding retains parser
state instead of materializing the complete corpus.

Failures are typed diagnostics carrying an error kind, UTF8 byte offset and
one-based scalar line/column. The twelve-case contract includes wrong tokens,
missing operators/operands/separators, EOF, Unicode and second-line locations,
whitespace, exact large integers and the 100000-statement corpus.

Both MiniCompiler/Syntax.lean and Syntax.ps are authored source. The independent
official Lean reference parses positive corpus inputs by splitting statements
and operands and native decimal conversion, sharing neither lexer nor parser
state machine. Negative locations are finite explicit contract expectations.

The application reuses the checked CLI argv transport and seven existing
capability adapters. Invoke `transform INPUT OUTPUT` with explicit readUtf8,
writeUtf8 and writeLine grants. Input is bounded by a 1 MiB host configuration,
within the existing 2 MiB Wasm IO ceiling and fixed 16 MiB linear arena. Source
failures preserve the old output. Host/compiler traps retain their host channel.

The performance input is 500000 bytes: `1+2;\\n` repeated 100000 times. Each
actual checked child process must produce
`{"statements":100000,"total":300000}`. Linux /usr/bin/time records elapsed
seconds and peak RSS for the full process, including adapter and source parsing.
External acceptance requires at most 120 seconds and 1 GiB peak RSS. No guest
fuel, compiler limit or existing regression limit is raised.

`scripts/practical-application-tests.mjs --compiler-application` retains the
corpus, native reference logs, checked bundles, exact identities and actual
per-case exit/console/file/measurement observations. Strict inventory validation
requires both grammars/all seven consumers, minimum Python and full exact-commit
qualification before this application becomes qualified. It cannot by itself
grant Practical Core release readiness or justify G2/G3 qualification.
