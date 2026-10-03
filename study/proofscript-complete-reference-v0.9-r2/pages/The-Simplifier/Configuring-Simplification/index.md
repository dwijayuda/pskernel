<a id="simp-config"></a>

# ProofScript — 15.6. Configuring Simplification

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

**Compiler and coverage boundary.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Simplifier/Configuring-Simplification/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Simplifier/Configuring-Simplification/index.html). Source Git blob: `2881767f61d5bebc99e3fe4650a430b71bc4686f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next"></a>

---

## 15.6. Configuring Simplification

`simp` is primarily configured via a configuration parameter, passed as a named argument called `config`.

<a id="Lean___Meta___Simp___Config___mk"></a>

**structure**

```text
Lean.Meta.Simp.Config : Type
```

The configuration for `simp`. Passed to `simp` using, for example, the `simp +contextual` or `simp (maxSteps := 100000)` syntax.

See also `Lean.Meta.Simp.neutralConfig` and `Lean.Meta.DSimp.Config`.

**Constructor**

```text
Lean.Meta.Simp.Config.mk
```

**Fields**

```text
maxSteps : Nat
```

The maximum number of subexpressions to visit when performing simplification. The default is 100000.

```text
maxDischargeDepth : Nat
```

When simp discharges side conditions for conditional lemmas, it can recursively apply simplification. The `maxDischargeDepth` (default: 2) is the maximum recursion depth when recursively applying simplification to side conditions.

```text
contextual : Bool
```

When `contextual` is true (default: `false`) and simplification encounters an implication `p → q` it includes `p` as an additional simp lemma when simplifying `q`.

```text
memoize : Bool
```

When true (default: `true`) then the simplifier caches the result of simplifying each sub-expression, if possible.

```text
singlePass : Bool
```

When `singlePass` is `true` (default: `false`), the simplifier runs through a single round of simplification, which consists of running pre-methods, recursing using congruence lemmas, and then running post-methods. Otherwise, when it is `false`, it iteratively applies this simplification procedure.

```text
zeta : Bool
```

When `true` (default: `true`), performs zeta reduction of `let` and `have` expressions. That is, `let x := v; e[x]` reduces to `e[v]`. If `zetaHave` is `false` then `have` expressions are not zeta reduced. See also `zetaDelta`.

```text
beta : Bool
```

When `true` (default: `true`), performs beta reduction of applications of `fun` expressions. That is, `(fun x => e[x]) v` reduces to `e[v]`.

```text
eta : Bool
```

TODO (currently unimplemented). When `true` (default: `true`), performs eta reduction for `fun` expressions. That is, `(fun x => f x)` reduces to `f`.

```text
etaStruct : Lean.Meta.EtaStructMode
```

Configures how to determine definitional equality between two structure instances. See documentation for `Lean.Meta.EtaStructMode`.

```text
iota : Bool
```

When `true` (default: `true`), reduces `match` expressions applied to constructors.

```text
proj : Bool
```

When `true` (default: `true`), reduces projections of structure constructors.

```text
decide : Bool
```

When `true` (default: `false`), rewrites a proposition `p` to `True` or `False` by inferring a `Decidable p` instance and reducing it.

```text
arith : Bool
```

When `true` (default: `false`), simplifies simple arithmetic expressions.

```text
autoUnfold : Bool
```

When `true` (default: `false`), unfolds applications of functions defined by pattern matching, when one of the patterns applies. This can be enabled using the `simp!` syntax.

```text
dsimp : Bool
```

When `true` (default: `true`) then switches to `dsimp` on dependent arguments if there is no congruence theorem that would allow `simp` to visit them. When `dsimp` is `false`, then the argument is not visited.

```text
failIfUnchanged : Bool
```

If `failIfUnchanged` is `true` (default: `true`), then calls to `simp`, `dsimp`, or `simp_all` will fail if they do not make progress.

```text
ground : Bool
```

If `ground` is `true` (default: `false`), then ground terms are reduced. A term is ground when it does not contain free or meta variables. Reduction is interrupted at a function application `f ...` if `f` is marked to not be unfolded. Ground term reduction applies `@[seval]` lemmas.

```text
unfoldPartialApp : Bool
```

If `unfoldPartialApp` is `true` (default: `false`), then calls to `simp`, `dsimp`, or `simp_all` will unfold even partial applications of `f` when we request `f` to be unfolded.

```text
zetaDelta : Bool
```

When `true` (default: `false`), local definitions are unfolded. That is, given a local context containing `x : t := e`, then the free variable `x` reduces to `e`. Otherwise, `x` must be provided as a `simp` argument.

```text
index : Bool
```

When `index` (default : `true`) is `false`, `simp` will only use the root symbol to find candidate `simp` theorems. It approximates Lean 3 `simp` behavior.

```text
implicitDefEqProofs : Bool
```

If `implicitDefEqProofs := true`, `simp` does not create proof terms when the input and output terms are definitionally equal.

```text
zetaUnused : Bool
```

When `true` (default : `true`), then `simp` removes unused `let` and `have` expressions: `let x := v; e` simplifies to `e` when `x` does not occur in `e`. This option takes precedence over `zeta` and `zetaHave`.

```text
catchRuntime : Bool
```

When `true` (default : `true`), then `simp` catches runtime exceptions and converts them into `simp` exceptions.

```text
zetaHave : Bool
```

When `false` (default: `true`), then disables zeta reduction of `have` expressions. If `zeta` is `false`, then this option has no effect. Unused `have`s are still removed if `zeta` or `zetaUnused` are true.

```text
letToHave : Bool
```

When `true` (default : `true`), then `simp` will attempt to transform `let`s into `have`s if they are non-dependent. This only applies when `zeta := false`.

```text
congrConsts : Bool
```

When `true` (default: `true`), `simp` tries to realize constant `f.congr_simp` when constructing an auxiliary congruence proof for `f`. This option exists because the termination prover uses `simp` and `withoutModifyingEnv` while constructing the termination proof. Thus, any constant realized by `simp` is deleted.

```text
bitVecOfNat : Bool
```

When `true` (default: `true`), the bitvector simprocs use `BitVec.ofNat` for representing bitvector literals.

```text
warnExponents : Bool
```

When `true` (default: `true`), the `^` simprocs generate an warning it the exponents are too big.

```text
suggestions : Bool
```

If `suggestions` is `true`, `simp?` will invoke the currently configured library suggestion engine on the current goal, and attempt to use the resulting suggestions as parameters to the `simp` tactic.

```text
maxSuggestions : Option Nat
```

Maximum number of library suggestions to use. If `none`, uses the default limit. Only relevant when `suggestions` is `true`.

```text
locals : Bool
```

If `locals` is `true`, `simp` will unfold all definitions from the current file. For local theorems, use `+suggestions` instead.

```text
instances : Bool
```

If `instances` is `true`, `simp` will visit instance arguments. If option `backward.dsimp.instances` is `true`, it overrides this field.

<a id="Lean___Meta___Simp___neutralConfig"></a>

**def**

```text
Lean.Meta.Simp.neutralConfig : Lean.Meta.Simp.Config
```

A neutral configuration for `simp`, turning off all reductions and other built-in simplifications.

<a id="Lean___Meta___DSimp___Config___mk"></a>

**structure**

```text
Lean.Meta.DSimp.Config : Type
```

The configuration for `dsimp`. Passed to `dsimp` using, for example, the `dsimp (config := {zeta := false})` syntax.

Implementation note: this structure is only used for processing the `(config := ...)` syntax, and it is not used internally. It is immediately converted to `Lean.Meta.Simp.Config` by `Lean.Elab.Tactic.elabSimpConfig`.

**Constructor**

```text
Lean.Meta.DSimp.Config.mk
```

**Fields**

```text
zeta : Bool
```

When `true` (default: `true`), performs zeta reduction of `let` and `have` expressions. That is, `let x := v; e[x]` reduces to `e[v]`. If `zetaHave` is `false` then `have` expressions are not zeta reduced. See also `zetaDelta`.

```text
beta : Bool
```

When `true` (default: `true`), performs beta reduction of applications of `fun` expressions. That is, `(fun x => e[x]) v` reduces to `e[v]`.

```text
eta : Bool
```

TODO (currently unimplemented). When `true` (default: `true`), performs eta reduction for `fun` expressions. That is, `(fun x => f x)` reduces to `f`.

```text
etaStruct : Lean.Meta.EtaStructMode
```

Configures how to determine definitional equality between two structure instances. See documentation for `Lean.Meta.EtaStructMode`.

```text
iota : Bool
```

When `true` (default: `true`), reduces `match` expressions applied to constructors.

```text
proj : Bool
```

When `true` (default: `true`), reduces projections of structure constructors.

```text
decide : Bool
```

When `true` (default: `false`), rewrites a proposition `p` to `True` or `False` by inferring a `Decidable p` instance and reducing it.

```text
autoUnfold : Bool
```

When `true` (default: `false`), unfolds applications of functions defined by pattern matching, when one of the patterns applies. This can be enabled using the `simp!` syntax.

```text
failIfUnchanged : Bool
```

If `failIfUnchanged` is `true` (default: `true`), then calls to `simp`, `dsimp`, or `simp_all` will fail if they do not make progress.

```text
unfoldPartialApp : Bool
```

If `unfoldPartialApp` is `true` (default: `false`), then calls to `simp`, `dsimp`, or `simp_all` will unfold even partial applications of `f` when we request `f` to be unfolded.

```text
zetaDelta : Bool
```

When `true` (default: `false`), local definitions are unfolded. That is, given a local context containing `x : t := e`, then the free variable `x` reduces to `e`. Otherwise, `x` must be provided as a `simp` argument.

```text
index : Bool
```

When `index` (default : `true`) is `false`, `simp` will only use the root symbol to find candidate `simp` theorems. It approximates Lean 3 `simp` behavior.

```text
zetaUnused : Bool
```

When `true` (default : `true`), then `simp` will remove unused `let` and `have` expressions: `let x := v; e` simplifies to `e` when `x` does not occur in `e`.

```text
zetaHave : Bool
```

When `false` (default: `true`), then disables zeta reduction of `have` expressions. If `zeta` is `false`, then this option has no effect. Unused `have`s are still removed if `zeta` or `zetaUnused` are true.

```text
locals : Bool
```

If `locals` is `true`, `dsimp` will unfold all definitions from the current file. For local theorems, use `+suggestions` instead.

```text
instances : Bool
```

If `instances` is `true`, `dsimp` will visit instance arguments. If option `backward.dsimp.instances` is `true`, it overrides this field.

<a id="simp-options"></a>
### 15.6.1. Options

Some global options affect `simp`:

<a id="simprocs"></a>

**option**

```text
simprocs
```

Default value: `true`

Enable/disable `simproc`s (simplification procedures).

<a id="tactic___simp___trace-next"></a>

**option**

```text
tactic.simp.trace
```

Default value: `false`

When tracing is enabled, calls to `simp` or `dsimp` will print an equivalent `simp only` call.

<a id="linter___unnecessarySimpa"></a>

**option**

```text
linter.unnecessarySimpa
```

Default value: `true`

enable the 'unnecessary simpa' linter

<a id="trace___Meta___Tactic___simp___rewrite"></a>

**option**

```text
trace.Meta.Tactic.simp.rewrite
```

Default value: `false`

enable/disable tracing for the given module and submodules

<a id="trace___Meta___Tactic___simp___discharge"></a>

**option**

```text
trace.Meta.Tactic.simp.discharge
```

Default value: `false`

enable/disable tracing for the given module and submodules
