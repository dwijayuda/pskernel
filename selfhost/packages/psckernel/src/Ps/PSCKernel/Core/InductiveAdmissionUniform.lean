import Ps.PSCKernel.Core.InductiveAdmissionPositive

-- Lean 4.34 checks recursive occurrences syntactically before WHNF. This is
-- necessary because reduction can erase a malformed occurrence before the
-- later positivity pass sees it.

partial def psCKernelInductiveUniformArgsMatch
    (args : List PsCKernelExpr)
    (offset : Nat) : Bool :=
  match args with
  | [] => true
  | arg :: rest =>
      match offset with
      | 0 => false
      | Nat.succ previous =>
          match arg with
          | PsCKernelExpr.bvar index =>
              if Nat.beq index previous then
                psCKernelInductiveUniformArgsMatch rest previous
              else
                false
          | _ => false


def psCKernelInductiveUniformTargetCheck?
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (numParams offset : Nat)
    (expr : PsCKernelExpr) : Option Bool :=
  let head := psCKernelExprGetAppFn expr
  let args := psCKernelExprGetAppArgs expr
  match head with
  | PsCKernelExpr.constE name levels =>
      if psCKernelNameEq name typeName then
        -- Over-applied occurrences are handled by descending until the
        -- parameter-prefix application is reached.
        if !Nat.blt numParams args.length then
          let exactArity := Nat.beq args.length numParams
          let enoughBinders := !Nat.blt offset numParams
          let exactLevels :=
            psCKernelLevelListEqStructural
              levels
              (psCKernelInductiveExpectedLevels levelParams)
          let exactParams :=
            psCKernelInductiveUniformArgsMatch args offset
          some (exactArity && enoughBinders && exactLevels && exactParams)
        else
          none
      else
        none
  | _ => none


partial def psCKernelInductiveUniformExprValid
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (numParams : Nat)
    (expr : PsCKernelExpr)
    (offset : Nat) : Bool :=
  match
      psCKernelInductiveUniformTargetCheck?
        typeName
        levelParams
        numParams
        offset
        expr with
  | some valid => valid
  | none =>
      match expr with
      | PsCKernelExpr.app fn arg =>
          if
              psCKernelInductiveUniformExprValid
                typeName levelParams numParams fn offset then
            psCKernelInductiveUniformExprValid
              typeName levelParams numParams arg offset
          else
            false
      | PsCKernelExpr.lam _ domain body _ =>
          if
              psCKernelInductiveUniformExprValid
                typeName levelParams numParams domain offset then
            psCKernelInductiveUniformExprValid
              typeName
              levelParams
              numParams
              body
              (Nat.add offset 1)
          else
            false
      | PsCKernelExpr.forallE _ domain body _ =>
          if
              psCKernelInductiveUniformExprValid
                typeName levelParams numParams domain offset then
            psCKernelInductiveUniformExprValid
              typeName
              levelParams
              numParams
              body
              (Nat.add offset 1)
          else
            false
      | PsCKernelExpr.letE _ declType value body _ =>
          if
              psCKernelInductiveUniformExprValid
                typeName levelParams numParams declType offset then
            if
                psCKernelInductiveUniformExprValid
                  typeName levelParams numParams value offset then
              psCKernelInductiveUniformExprValid
                typeName
                levelParams
                numParams
                body
                (Nat.add offset 1)
            else
              false
          else
            false
      | PsCKernelExpr.proj _ _ value =>
          psCKernelInductiveUniformExprValid
            typeName levelParams numParams value offset
      | _ => true


partial def psCKernelInductiveUniformCtorsValid
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (numParams : Nat)
    (ctors : List PsCKernelConstructorDecl) : Bool :=
  match ctors with
  | [] => true
  | ctor :: rest =>
      if
          psCKernelInductiveUniformExprValid
            typeName
            levelParams
            numParams
            ctor.type
            0 then
        psCKernelInductiveUniformCtorsValid
          typeName
          levelParams
          numParams
          rest
      else
        false


def psCKernelValidateOrdinaryInductiveUniform?
    (env : PsCKernelEnvironment)
    (decl : PsCKernelInductiveDecl) :
    Option PsCKernelOrdinaryInductivePositiveValidation :=
  match decl.types with
  | [typeDecl] =>
      if
          psCKernelInductiveUniformCtorsValid
            typeDecl.name
            decl.levelParams
            decl.numParams
            typeDecl.ctors then
        psCKernelValidateOrdinaryInductivePositive? env decl
      else
        none
  | _ => none
