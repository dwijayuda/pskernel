import Ps.BackendRust.Expr

-- The loop carries a tuple so arguments are evaluated before replacement.
-- Recognized eta aliases freeze captures before binding; shadowing hides aliases.
def psRustTailAnyAlternative
    (check : List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool)
    (locals : List String) (aliases : List PsRustTailAlias)
    (alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) : Bool :=
  match alternatives with
  | List.nil => false
  | List.cons alternative rest =>
      let payload := Prod.snd alternative;
      let names := psRustAddBindingNames (Prod.fst payload) List.nil;
      if check (psRustAddBindingNames (Prod.fst payload) locals) (psRustTailHideAliases names aliases) (Prod.snd payload) then true
      else psRustTailAnyAlternative check locals aliases rest

def psRustHasTailAliasWorker (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) (_aliases : List PsRustTailAlias) (_expr : PsVerifiedIrExpr) => false
  | Nat.succ remaining =>
      let smaller : List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool :=
        psRustHasTailAliasWorker declaration remaining;
      fun (locals : List String) (aliases : List PsRustTailAlias) (expr : PsVerifiedIrExpr) =>
        match psRustTailCallFor declaration locals aliases expr with
        | Option.some _ => true
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name _ value body =>
                smaller (List.cons name locals) (psRustTailEnterAlias declaration locals aliases remaining name value) body
            | PsVerifiedIrExpr.ifE _ thenBranch elseBranch =>
                if smaller locals aliases thenBranch then true else smaller locals aliases elseBranch
            | PsVerifiedIrExpr.matchE _ _ _ alternatives => psRustTailAnyAlternative smaller locals aliases alternatives
            | _ => false

def psRustHasTailWorker (declaration : PsVerifiedIrDeclaration) (fuel : Nat)
    (locals : List String) (expr : PsVerifiedIrExpr) : Bool :=
  psRustHasTailAliasWorker declaration fuel locals List.nil expr

def psRustDeclarationBody (ctx : PsRustContext) (d : PsVerifiedIrDeclaration) :
    Except String PsDoc := do
  let locals := d.parameters.map (·.name)
  let hasTail := !d.parameters.isEmpty && psRustHasTailWorker d 65536 locals d.body
  let body ← psRustExpr 65536 { ctx with locals, tail? := if hasTail then some d else none } [] d.body
  if !hasTail then return body
  let tuple := "(" ++ String.intercalate ", " locals ++ ",)"
  return psDocJoin .hardline [
    .text ("let mut __ps_tail_state = " ++ tuple ++ ";"),
    psDocBlock "loop" [
      .text ("let " ++ tuple ++ " = __ps_tail_state;"),
      .append (.text "break ") (.append body (.text ";"))]]
