import Ps.Elab.Basic

def psElabExprHasLoose (term : PsExpr) (depth : Nat := 0) : Bool :=
  match term with
  | .bvar index => index >= depth
  | .app fn arg => psElabExprHasLoose fn depth || psElabExprHasLoose arg depth
  | .lam _ type body _ | .forallE _ type body _ =>
    psElabExprHasLoose type depth || psElabExprHasLoose body (depth + 1)
  | .letE _ type value body => psElabExprHasLoose type depth ||
    psElabExprHasLoose value depth || psElabExprHasLoose body (depth + 1)
  | .proj _ _ value => psElabExprHasLoose value depth
  | _ => false

def psElabExprHeadArgs : PsExpr → Nat
  | .app fn _ => psElabExprHeadArgs fn + 1
  | .letE _ _ _ body => psElabExprHeadArgs body
  | _ => 0

def psElabExprQuickHead : PsExpr → Option PsExpr
  | .app fn _ => psElabExprQuickHead fn
  | .letE _ _ _ body => psElabExprQuickHead body
  | .bvar _ => none
  | term => some term

def psElabExprKeyHead (fuel : Nat) (term : PsExpr) : Except PsElabError PsExpr := do
  if let some head := psElabExprQuickHead term then return head
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match term with
    | .app fn _ => psElabExprKeyHead fuel fn
    | .letE _ _ value body => psElabExprKeyHead fuel (psExprInstantiate1 body value)
    | .bvar index => throw (.infer (.looseBoundVariable index))
    | _ => return term

def psElabExprSameHead (left right : PsExpr) : Bool :=
  match left, right with
  | .fvar a, .fvar b | .mvar a, .mvar b => a == b
  | .constE a _, .constE b _ => psNameEq a b
  | .proj a i _, .proj b j _ => psNameEq a b && i == j
  | .lit a, .lit b => psLiteralEq a b
  | .sortE _, .sortE _ | .lam .., .lam .. | .forallE .., .forallE .. => true
  | _, _ => false

-- Required metavariable assignments travel with the abstraction result.
-- Its caller checks the complete generalized telescope before using it.
def psElabKeyAbstractAt (transparency : PsTransparency) (context : PsElabContext) (pattern : PsExpr)
    (term : PsExpr) (depth : Nat) : Except PsElabError (PsElabContext × PsExpr) := do
  if !psElabExprHasLoose term &&
      psElabExprHeadArgs term == psElabExprHeadArgs pattern then
    let head ← psElabExprKeyHead psInferDefaultFuel term
    let patternHead ← psElabExprKeyHead psInferDefaultFuel pattern
    if psElabExprSameHead head patternHead then
      let unified := psUnifyWithTransparency transparency context.environment
        context.localContext context.metaContext term pattern
      if unified.resourceExceeded then throw .fuelExhausted
      if unified.success then
        return (psElabContextWithMeta context unified.context, .bvar depth)
  match term with
  | .app fn arg =>
    let (context, fn) ← psElabKeyAbstractAt transparency context pattern fn depth
    let (context, arg) ← psElabKeyAbstractAt transparency context pattern arg depth
    return (context, .app fn arg)
  | .lam name type body binder =>
    let (context, type) ← psElabKeyAbstractAt transparency context pattern type depth
    let (context, body) ← psElabKeyAbstractAt transparency context pattern body (depth + 1)
    return (context, .lam name type body binder)
  | .forallE name type body binder =>
    let (context, type) ← psElabKeyAbstractAt transparency context pattern type depth
    let (context, body) ← psElabKeyAbstractAt transparency context pattern body (depth + 1)
    return (context, .forallE name type body binder)
  | .letE name type value body =>
    let (context, type) ← psElabKeyAbstractAt transparency context pattern type depth
    let (context, value) ← psElabKeyAbstractAt transparency context pattern value depth
    let (context, body) ← psElabKeyAbstractAt transparency context pattern body (depth + 1)
    return (context, .letE name type value body)
  | .proj name index value =>
    let (context, value) ← psElabKeyAbstractAt transparency context pattern value depth
    return (context, .proj name index value)
  | _ => return (context, term)

def psElabKeyAbstract (context : PsElabContext) (pattern term : PsExpr)
    (transparency : PsTransparency := .all) :
    Except PsElabError (PsElabContext × PsExpr) :=
  let term := psMetaInstantiate context.metaContext term
  match pattern with
  | .fvar id => pure (context, psExprAbstractFVar id term)
  | _ => psElabKeyAbstractAt transparency context pattern term 0

