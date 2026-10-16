import Ps.BackendEcma.Syntax

namespace PsEcma

-- Conservative suspension analysis over the ACTUAL lowered AST. Keeping this
-- after intrinsic lowering avoids a second, potentially stale callback roster.
-- Exhaustion means fallback, never permission to emit yield in a normal body.
mutual
def exprSynchronous : Nat → Expr → Bool
  | 0, _ => false
  | fuel + 1, value =>
    let visit := exprSynchronous fuel
    match value with
    | .atom _ => true
    | .unary op value => !op.startsWith "yield" && visit value
    | .binary _ a b => visit a && visit b
    | .conditional c a b => visit c && visit a && visit b
    | .member value _ _ | .cast value _ | .nonnull value | .generic value _ => visit value
    | .index a b => visit a && visit b
    | .call fn _ args => visit fn && args.all visit
    | .newE _ _ args | .array args => args.all visit
    | .object fields => fields.all (fun f => visit f.snd)
    | .functionE generator _ _ _ body => !generator && body.all (stmtSynchronous fuel)
def stmtSynchronous : Nat → Stmt → Bool
  | 0, _ => false
  | fuel + 1, statement =>
    let expr := exprSynchronous fuel
    let block := fun (body : List Stmt) => body.all (stmtSynchronous fuel)
    match statement with
    | .expression value | .returnE value | .throwE value => expr value
    | .binding _ _ _ value => match value with | none => true | some value => expr value
    | .continueE => true
    | .block body => block body
    | .ifE c a b => expr c && block a && block b
    | .whileE c body | .forOf _ c body => expr c && block body
    | .switchE value cases => expr value && cases.all (fun c => expr c.fst && block c.snd)
    | .functionD _ generator _ _ _ _ body => !generator && block body
end

-- Preserve the same lexical boundary, argument order and once-only evaluation.
-- Only the unnecessary generator protocol disappears in suspension-free scopes.
def scopeExpr (body : List Stmt) (parameters : List Parameter := []) (args : List Expr := []) : Expr :=
  if body.all (stmtSynchronous 4096) then invoke parameters "" body args
  else delegate body parameters args

end PsEcma
