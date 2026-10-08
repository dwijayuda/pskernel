import Lean

/-!
ProofScript-owned syntax is lowered into Lean's pinned parser/elaborator.
These are additive *bounded* aliases, not a separate type checker.

The comprehensive ProofScript A.18 grammar (braced blocks, comma-separated
calls, indexed inductive headers, extended effect syntax, etc.) is not yet
implemented; each accepted spelling below has an unambiguous Lean lowering.
-/

open Lean

namespace PSCVL

syntax (name := pscvConst) "const " ident ":" term ":=" term : command

macro_rules
  | `(const $name:ident : $ty:term := $value:term) =>
    `(def $name : $ty := $value)

/-- One comma-delimited explicit ProofScript binder (no JS-like defaults). -/
declare_syntax_cat pscvBinder
syntax ident ":" term : pscvBinder

syntax (name := pscvFunction) "function " ident "(" pscvBinder,* ")" ":" term ":=" term : command

macro_rules
  | `(function $f:ident ($[$bs:pscvBinder],*) : $result:term := $body:term) => do
    let mut leanBinders : Array (TSyntax ``Lean.Parser.Term.bracketedBinder) := #[]
    for b in bs do
      let `(pscvBinder| $x:ident : $t:term) := b
        | Macro.throwUnsupported
      leanBinders := leanBinders.push (← `(($x:ident : $t:term)))
    `(def $f:ident $leanBinders* : $result:term := $body:term)

/-- Contracted function syntax is the same verified Lean 4.35 contract
semantics as `def`: `f.spec` must be proved by Lean's `vcgen`. -/
syntax (name := pscvFunctionContract)
  "function " ident "(" pscvBinder,* ")" ":" term
  "requires" term "ensures" ident "=>" term ":=" term : command

macro_rules
  | `(function $f:ident ($[$bs:pscvBinder],*) : $result:term
      requires $pre:term ensures $rv:ident => $post:term := $body:term) => do
    let mut leanBinders : Array (TSyntax ``Lean.Parser.Term.bracketedBinder) := #[]
    for b in bs do
      let `(pscvBinder| $x:ident : $t:term) := b
        | Macro.throwUnsupported
      leanBinders := leanBinders.push (← `(($x:ident : $t:term)))
    `(def $f:ident $leanBinders* : $result:term
        requires $pre:term
        ensures $rv:ident => $post:term := $body:term)

/-- Finite refinement-type sugar lowering to Lean's kernel-checked Subtype. -/
syntax (name := pscvRefine) "refine " "type " ident ":=" term
  "where " ident "=>" term : command

macro_rules
  | `(refine type $name:ident := $t:term where $x:ident => $predicate:term) =>
    `(abbrev $name : Type := { $x:ident : $t:term // $predicate:term })

end PSCVL
