import Ps.Elab.Basic

-- The ordinary proof reducer follows the existing checked reduction rules
-- at default transparency. Exhaustion is reported, never a residual answer.
-- Native reference: Lean4.35.0 Meta/WHNF and Elab/Tactic/Decide.doElab.
def psProofWhnfWithFuel (fuel : Nat) (context : PsElabContext)
    (expression : PsExpr) : Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let step := psProofWhnfWithFuel fuel context
    let view := psReduceAppView (psMetaInstantiate context.metaContext expression)
    let applied := psExprApplyMany view.head view.args
    match view.head with
    | .fvar id =>
      match psLocalFindById context.localContext id with
      | some (.letDecl _ _ _ value) => step (psExprApplyMany value view.args)
      | _ => pure applied
    | .letE _ _ value body =>
      step (psExprApplyMany (psExprInstantiate1 body value) view.args)
    | .lam _ _ body _ =>
      match view.args with
      | [] => pure view.head
      | first :: rest => step (psExprApplyMany (psExprInstantiate1 body first) rest)
    | .proj owner index major =>
      let major ← step major
      match psReduceProjectionIota (fun value => value) context.environment owner index major with
      | some value => step (psExprApplyMany value view.args)
      | none => pure (psExprApplyMany (.proj owner index major) view.args)
    | .constE name levels =>
      if psNameEq name psNatZeroName then
        return ← step (psExprApplyMany (.lit (.natural 0)) view.args)
      let arguments ←
        if (psNameEq name psNatSuccName && view.args.length == 1) ||
            ((psReduceNatBinary name).isSome && view.args.length == 2) then
          view.args.mapM step
        else pure view.args
      let application := psExprApplyMany view.head arguments
      if let some value := psReduceNatPrimitive (fun value => value) application then
        return ← step value
      let candidate ← match psEnvironmentFindRecursor context.environment name with
        | some info => do
          let position := info.numParams + info.numMotives + info.numMinors + info.numIndices
          match arguments[position]? with
          | none => pure none
          | some major => do
            let major ← step major
            let args := arguments.take position ++ [major] ++ arguments.drop (position + 1)
            let metadataReduce := psWhnf context.environment context.metaContext context.localContext
            pure (psReduceIota metadataReduce context.environment
              (psExprApplyMany view.head args))
        | none =>
          match psEnvironmentFind context.environment name with
          | some (.quotientDecl _ _ _ kind) => do
            let position? := match kind with
              | .lift => some 5
              | .ind => some 4
              | _ => none
            match position? with
            | none => pure none
            | some position =>
              match arguments[position]? with
              | none => pure none
              | some major => do
                let major ← step major
                let args := arguments.take position ++ [major] ++ arguments.drop (position + 1)
                pure (psReduceQuotientIota (fun value => value) context.environment
                  (psExprApplyMany view.head args))
          | _ => pure none
      if let some value := candidate then return ← step value
      let some declaration := psEnvironmentFind context.environment name
        | throw (.unknownName name)
      if !psEnvironmentCanUnfold context.environment .«default» name then
        return application
      match psDeclarationValue declaration with
      | none => pure application
      | some body =>
        let parameters := psDeclarationLevelParams declaration
        if parameters.length != levels.length then throw .typeMismatch
        step (psExprApplyMany (psExprInstantiateLevelParams parameters levels body) arguments)
    | _ => pure applied
