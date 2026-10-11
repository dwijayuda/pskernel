# Class output parameters and dictionary dependencies

Class registration computes output term positions and output-only universe
positions from the checked class telescope. The outParam wrapper is the native
reducible identity. Ordinary input parameters cannot depend on outputs;
instance parameters that depend on outputs are themselves outputs, matching
the pinned class registry rules. Metadata stays in the portable environment.

Instance search waits for known inputs. Before searching, it replaces all
output arguments and output-only universes with fresh metavariables, even when
the caller supplied a concrete output. It selects a dictionary using existing
local-first, priority and declaration-order rules, then reconciles that
dictionary's type with the original target. A mismatching output is failure;
it must not silently select another lower-priority instance.

Cycle keys erase output positions and output-only levels. Fresh output IDs
therefore cannot hide a recursive search cycle. Candidate branches retain their
own immutable metavariable snapshots. Search remains bounded; tabling and
higher-order typeclass targets are not claimed.

A shared dictionary worklist replaces separate fixed-order application and
candidate solvers. It postpones unavailable inputs, processes independent
dictionaries, and retries only when a dictionary was solved. Ordinary inferred
parameters are required to be complete after the dictionaries have run, since
an output of a nested instance can determine them. No-progress passes fail.
The bound is proportional to the number of pending dictionaries.

The existing composite checks polymorphic output inference in let bindings,
local dictionaries, and nested dictionaries. Four refusals cover illegal
dependent inputs, output-directed priority changes, guessed inputs and cycles
with fresh outputs. These are semantic boundary checks, not a large generated
suite. Native Lean and both checked-IR runtime backends remain the execution
path; no compiler-source translation, self-hosting or pskernel-core.

Reference implementation: Lean/Class.lean and Lean/Meta/SynthInstance.lean at
c29b6dda4f7c20e3eeaa717c4e565663c5cfa364. Semi-output parameters, tabled synthesis,
default-instance scheduling and complete non-ground inference remain separate.
