import Ps.Meta.Iota
import Ps.Core.Abstract
import Ps.Core.Equality

-- The single-family recursor contract is shared by preparation and runtime
-- lowering. It does not infer recursion from a name or constructor spelling.
structure PsRecursorApplication where
  info : PsRecursorInfo
  family : PsInductiveInfo
  head : PsExpr
  fixedArgs : List PsExpr
  indices : List PsExpr
  major : PsExpr
  suffix : List PsExpr

def psRecursorApplication (environment : PsEnvironment) (expr : PsExpr) :
    Option PsRecursorApplication := do
  let view := psReduceAppView expr
  let .constE name levels := view.head | none
  let info ← psEnvironmentFindRecursor environment name
  let [familyName] := info.inductiveNames | none
  let family ← psEnvironmentFindInductive environment familyName
  if info.numMotives != 1 || info.numMinors != family.constructors.length ||
      info.numParams != family.numParams || info.numIndices != family.numIndices ||
      levels.length != info.levelParams.length then none else do
    let prefixSize := info.numParams + 1 + info.numMinors
    let major ← view.args[prefixSize + info.numIndices]?
    return {
      info, family, head := view.head, fixedArgs := view.args.take prefixSize
      indices := (view.args.drop prefixSize).take info.numIndices
      major, suffix := view.args.drop (prefixSize + info.numIndices + 1) }

def psRecursorContainsLocal (id : Nat) (expr : PsExpr) : Bool :=
  !(psExprAlphaEq expr (psExprAbstractFVar id expr))

def psRecursorVaryingLocals (major : PsExpr) (indices minors : List PsExpr) :
    Option (List Nat) := do
  let ids ← (major :: indices).mapM fun expr =>
    match expr with
    | .fvar id => some id
    | _ => none
  if ids.eraseDups.length != ids.length ||
      minors.any (fun minor => ids.any (fun id => psRecursorContainsLocal id minor)) then none
  else some ids

def psRecursorUsesBound (expr : PsExpr) (count depth : Nat) : Bool :=
  match expr with
  | .bvar index => depth <= index && index < depth + count
  | .app fn arg => psRecursorUsesBound fn count depth || psRecursorUsesBound arg count depth
  | .lam _ type body _ | .forallE _ type body _ =>
    psRecursorUsesBound type count depth || psRecursorUsesBound body count (depth + 1)
  | .letE _ type value body =>
    psRecursorUsesBound type count depth || psRecursorUsesBound value count depth ||
      psRecursorUsesBound body count (depth + 1)
  | .proj _ _ value => psRecursorUsesBound value count depth
  | _ => false

def psRecursorStripLambdas (count : Nat) (expr : PsExpr) : Option PsExpr :=
  match count with
  | 0 => some expr
  | count + 1 =>
    match expr with
    | .lam _ _ body _ => psRecursorStripLambdas count body
    | _ => none

def psRecursorUsesHypotheses (environment : PsEnvironment)
    (view : PsRecursorApplication) : Bool :=
  view.family.constructors.zipIdx |>.any fun entry =>
    match psEnvironmentFindConstructor environment entry.fst,
        view.fixedArgs[view.info.numParams + 1 + entry.snd]? with
    | some ctor, some minor =>
      if ctor.recursiveFields.isEmpty then false else
        match psRecursorStripLambdas (ctor.numFields + ctor.recursiveFields.length) minor with
        | some body => psRecursorUsesBound body ctor.recursiveFields.length 0
        | none => true
    | _, _ => false
