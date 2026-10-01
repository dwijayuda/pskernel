# @proofscript/lean4export

Status: **MVP / private**  
Trust: **untrusted support layer**

Cross-platform process and streaming transport around a pinned Lean exporter.

## Responsibilities

- locate Lean on Windows/macOS/Linux
- validate the requested Lean version
- run an explicit exporter script
- stream exporter output line-by-line
- collect bounded exports
- write large exports directly to disk
- optionally wrap a bounded export as an `@proofscript/module` artifact

## Non-responsibilities

This package does not decide whether a declaration is logically valid. Exported declarations become trusted only after replay through pskernel.

The exporter script is also explicit. The package does not silently substitute a different Lean version or exporter.

## CLI

```bash
proofscript-lean4export version

proofscript-lean4export run \
  Init.Prelude \
  ../../oracle/replay-probe/DependencyExport.lean \
  init.ndjson \
  --all
```

The pskernel repository's current exporter remains the compatibility reference while this package is private.
