# PSC1 ProofScript examples

**65 independent example projects · 90 `.ps` source files · 59 positive projects · 6 intentional diagnostic projects**

This collection targets `proofscript@0.1.0-psc1.12` and the PSC1 VS Code extension 0.1.1. It progresses from simple values to higher-order functions, custom data, recursion, finite loops, explicit proof terms, and multi-module applications. Each project includes its own `proofscript.json`, explanatory source comments, a short README, and expected outcomes.

## Start in VS Code

1. Extract the ZIP and open `psc1-examples.code-workspace`, or open the extracted folder.
2. Open `01-basics/01-typed-values/Main.ps` and allow the check to finish.
3. Run **ProofScript: Show Infoview**. Move the cursor into a declaration to inspect its type and current verification status.
4. Follow [INDEX.md](INDEX.md) to choose another example. Keep each example's files together.

Use VS Code 1.143.1 or newer and the updated [PSC1 editor 0.1.1 package](https://github.com/dwijayuda/pskernel/actions/runs/40591485183/artifacts/12773214308). Install `proofscript-psc1-0.1.1.vsix` from that archive and reload VS Code. The extension supplies its compiler; these examples require no extra source libraries.

There is no umbrella `proofscript.json`: each example is a separate project. This lets small examples reuse readable names such as `result`, `Main`, and `Support`. The editor finds the nearest project file when a source is opened.

## Contents and suggested order

| Folder | Projects | Focus |
| --- | ---: | --- |
| [01-basics](01-basics/README.md) | 16 | Values, arithmetic, functions, conditionals, lambdas, closures, composition, namespaces, polymorphism, and strings |
| [02-data](02-data/README.md) | 16 | Enums, payloads, options, generic data, tuples, structures, lists, structural recursion, trees, and an interpreter |
| [03-control-flow](03-control-flow/README.md) | 8 | Local mutation, finite loops, numeric ranges, early returns, and closure capture |
| [04-proofs](04-proofs/README.md) | 16 | Implication, proof composition, explicit Church logical encodings, and Leibniz equality |
| [05-multi-file-projects](05-multi-file-projects/README.md) | 3 | Ordered imports, transitive dependencies, and separating data from policy |
| [90-intentional-errors](90-intentional-errors/README.md) | 6 | Clearly labeled parse and elaboration errors, with repair notes |

Start with basics 01–10, then options and records. Continue with finite loops and recursive data. Proofs 01–07 introduce terms directly; proofs 08–16 define their logical encodings explicitly in `Support.ps`. Finish by inspecting the multi-file manifests and deliberately repairing the diagnostic examples.

## Read the `.ps` syntax

Functions use typed parameter lists and comma-separated calls:

```text
def addFee(price : Nat, fee : Nat) : Nat := price + fee
def result : Nat := addFee(40, 2)
```

Conditional values use braces:

```text
def selected : Nat := if (true) { 7 } else { 9 }
```

`Nat` is a nonnegative integer type; subtraction saturates at zero. Explicit type annotations make the examples easy to inspect. `Support.ps` or `Data.ps` files hold reusable generic/aggregate helpers where needed; `Main.ps` exposes scalar runtime examples supported by this compiler distribution.

The proofs are explicit terms. Church conjunction/disjunction/equivalence and Leibniz equality are locally defined encodings, with those definitions visible in the source. Their names do not promise additional standard-library or tactic APIs.

## Expected results and verification

Every positive project requests checked assurance. Qualification runs the existing public compiler APIs against the exact source inventory, requires genuine independent Lean Wasm kernel acceptance, verifies admission/source identities, and runs the emitted JavaScript to check the exported values listed in each project's `metadata.json`.

The scalar outputs in proof examples are only runtime smoke checks. Acceptance of the theorem declarations is established separately by the genuine kernel, not by those scalar values. The Infoview displays verification and types; it does not evaluate a declaration as a REPL.

The six projects under `90-intentional-errors` are expected to be rejected at the documented compiler phase. Red diagnostics there are intentional. Their comments explain the issue and a repair. Keep those projects separate from positive demonstrations.

See [VALIDATION.md](VALIDATION.md) for the exact successful run and [validation-results.json](validation-results.json) for source hashes, receipts, diagnostic phases, and observed exported values. The ZIP is produced only after every expected outcome matches. `CHECKSUMS.sha256` covers its payload files.

## Optional installed CLI use

If the matching qualified `proofscript@0.1.0-psc1.12` command is already installed on Linux, select one example with `-p`:

```sh
psc check -p 01-basics/01-typed-values
psc compile -p 05-multi-file-projects/02-three-module-pipeline
```

The compiler package itself is not included in this ZIP. The full CLI target/build pipeline retains its existing platform restrictions; use editor 0.1.1 for the qualified Windows/macOS editor checking path. The optional CLI guide is in the [compiler repository](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/docs/guides/cli.md).

## Try small changes

- Change an input and predict the new exported value before checking.
- Hover helper declarations and final result declarations to inspect their types.
- Add an enum constructor, then update every matching branch.
- Extend one record and adjust its constructor call.
- Change the order of function composition and explain the different result.
- In a proof, follow which hypothesis supplies each requested proposition.
- In a multi-file project, follow imports and compare them with the manifest's dependency order.

The checked language and genuine compiler remain authoritative. These examples do not extend compiler semantics or kernel authority. Source and verification provenance are recorded in [SOURCES.md](SOURCES.md).
