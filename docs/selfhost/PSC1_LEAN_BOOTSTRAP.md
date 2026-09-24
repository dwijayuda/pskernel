# PSC1 Lean bootstrap architecture

Branch: `selfhost/psc1-lean-bootstrap`

This branch starts the first real ProofScript self-host experiment. It is
isolated from `main` until the bootstrap lane proves useful.

## Goal

Build the ProofScript compiler first in the supported Lean subset, continuously
translate that source to canonical `.ps`, and eventually reach:

```text
compiler.lean --PSC0--> compiler.ts --tsc--> PSC1.js
compiler.lean --PSC1--> compiler.ts --tsc--> PSC2.js

compiler.lean --translate--> compiler.ps
compiler.ps   --PSC1--> PSC2-ps.js
```

PSC0 is the current TypeScript implementation. The first self-hosting claim is
not made until PSC2 is stable.

## What to copy and what not to copy

Use the current TypeScript implementation as the executable behavioral oracle,
not as a file-for-file porting template.

Use Lean 4.34 as the semantic/design reference for:
- core expressions and declarations;
- elaboration architecture;
- parser state and diagnostics;
- environments/names;
- Meta state, unification and instance search;
- compiler bootstrap discipline.

Do not reproduce Lean's broad macro/metaprogramming platform unless the PSC1
compiler actually needs it.

Port **semantic responsibilities**, not npm package boundaries.

## Bootstrap module architecture

The intended self-hosted compiler modules are:

1. `ProofScript.Compiler.Data`
   - SourcePos / Span / Diagnostic
   - small compiler-owned enums and records
2. `ProofScript.Compiler.Name`
   - qualified names and deterministic name operations
3. `ProofScript.Compiler.Json`
   - canonical JSON value/parser/encoder used by the kernel bridge
4. `ProofScript.Compiler.KernelCodec`
   - Name/Level/Expr/declaration request/response codecs
5. `ProofScript.Compiler.CheckedCore`
   - compiler-owned checked-core data view; no second checker
6. `ProofScript.Compiler.IR`
   - the small verified executable IR
7. `ProofScript.Compiler.Erase`
   - checked core -> executable IR
8. `ProofScript.Compiler.EmitTS`
   - verified IR -> deterministic TypeScript text
9. `ProofScript.Compiler.Lexer`
   - String/Char/UTF-8 source traversal
10. `ProofScript.Compiler.Syntax`
    - canonical source AST
11. `ProofScript.Compiler.Parser`
    - bounded .ps and supported-.lean parsing
12. `ProofScript.Compiler.Environment`
    - imports, declarations, names and instance indexes
13. `ProofScript.Compiler.Meta`
    - metavariables, rollback, bounded unification/instance synthesis
14. `ProofScript.Compiler.Elab`
    - source AST -> Lean-compatible core terms
15. `ProofScript.Compiler.Driver`
    - orchestration only

These are logical modules. They may be merged when keeping fewer modules makes
the language/compiler simpler.

## Explicit external boundaries

The first self-hosted compiler does not rewrite these in Lean/ProofScript:

- pskernel itself;
- filesystem/path/process APIs;
- npm/Node resolution;
- TypeScript compiler invocation;
- JavaScript execution.

They remain versioned host capabilities. The kernel boundary is initially the
canonical String/JSON protocol from SH6b.

## Source discipline

Every self-hosted semantic compiler module starts in supported `.lean`, but it
must remain inside the intersection of:

1. official Lean 4.34 syntax/semantics;
2. ProofScript's supported Lean frontend;
3. the PSC1 required language subset.

Until namespace support enters the frozen subset, bootstrap declarations use
globally unique `Ps*` names instead of depending on Lean namespaces.

Do not add a language feature just because a compiler module would be prettier
with it. Prefer the PSC1 core or a library helper. Promote an optional feature
only when the implementation becomes unreasonable without it.

## Per-module admission gate

A module is considered landed only when the applicable stages are green:

```text
module.lean
  -> official Lean 4.34 check
  -> ProofScript .lean parse/elaborate
  -> pskernel checked core
  -> canonical module.ps
  -> ProofScript .ps parse/elaborate
  -> same checked-core fingerprint
  -> same verified-IR fingerprint
  -> TypeScript emission
  -> JavaScript execution when executable
```

At the beginning, some later stages may not yet be expressible by the existing
PSC0 frontend. Such a missing capability is recorded as a concrete blocker;
the compiler module is not rewritten around a hidden TypeScript semantic path.

## Implementation order

Do not start with the parser.

The cheapest bootstrap path is:

```text
Data
-> Name / JSON / kernel codec
-> CheckedCore data view
-> Verified IR
-> TypeScript text builder/emitter
-> erasure
-> lexer
-> source AST/parser
-> environment/name resolution
-> Meta
-> elaboration
-> driver
```

This lets us self-host pure data and deterministic transformations first, while
the current TypeScript parser/elaborator continues to compile those modules.

## First checkpoint

The first checkpoint is intentionally small:

- branch exists from an exact `main` commit;
- one canonical `.lean` compiler-data module;
- official Lean 4.34 accepts it;
- PSC0 checks/builds it through pskernel and verified TS/JS;
- `.lean -> .ps -> .lean` is canonical-stable;
- no new kernel semantics and no new language feature are introduced.

Only after that gate should the branch begin moving real compiler behavior out
of TypeScript.
