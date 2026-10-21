import Ps.BackendTs.Checked
import Ps.BackendTs.Sh1Target

/-
Opt-in, bounded saturation of monomorphic function-valued declarations.

The existing declaration entries, exported types and partial applications remain
unchanged. A private flat helper is used only for an exact saturated global call.
Moving the intervening stages across later arguments requires both to be total,
effect-free expressions from the small Nat/Bool whitelist below. Arbitrary calls,
callbacks, array operations, projections and matches are deliberately excluded.

Recognition is an optimization, never admission evidence. The checked entry
checks the original IR, then the exact transformed IR and target names. Any
recognition, freshness, transformed-check or target-check refusal emits the
original module. The source elaborator, erasure arities and kernel budgets are
not changed. No compiler-preservation theorem is claimed by these finite gates.
-/

structure PsTsSatCandidate where
  sourceName : String
  helper : PsVerifiedIrDeclaration
  entryArity : Nat
  stages : Nat

structure PsTsSatExprResult where
  expr : PsVerifiedIrExpr
  calls : Nat

structure PsTsSatListResult where
  expressions : List PsVerifiedIrExpr
  calls : Nat

structure PsTsSatFieldsResult where
  fields : List (Prod String PsVerifiedIrExpr)
  calls : Nat

structure PsTsSatAlternativesResult where
  alternatives : List
    (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))
  calls : Nat

structure PsTsSatSpine where
  name : String
  groups : List (List PsVerifiedIrExpr)

structure PsTsSatPlan where
  module : PsVerifiedIrModule
  privateNames : List String
  helperCount : Nat
  rewrittenCalls : Nat

def psTsSatAllowedIntrinsic (operation : PsVerifiedIrIntrinsic) : Bool :=
  match operation with
  | .natAdd => true
  | .natSub => true
  | .natMul => true
  | .natDiv => true
  | .natMod => true
  | .natEq => true
  | .natNe => true
  | .natLe => true
  | .natLt => true
  | .boolNot => true
  | .boolAnd => true
  | .boolOr => true
  | .boolEq => true
  | .boolNe => true
  | _ => false

def psTsSatPureWithFuel (fuel : Nat) (expr : PsVerifiedIrExpr) : Bool :=
  match fuel with
  | Nat.zero => false
  | Nat.succ remaining =>
      let pure : PsVerifiedIrExpr -> Bool := psTsSatPureWithFuel remaining;
      match expr with
      | .var _ => true
      | .literal value =>
          match value with
          | .natural _ => true
          | .bool _ => true
          | _ => false
      | .intrinsic operation types arguments =>
          if psListIsEmpty types then
            if psTsSatAllowedIntrinsic operation then
              if psListAny (fun (value : PsVerifiedIrExpr) => if pure value then false else true) arguments then false else true
            else false
          else false
      | .ifE condition left right =>
          if pure condition then if pure left then pure right else false else false
      | _ => false

def psTsSatParameterNamed
    (parameters : List PsVerifiedIrParameter) (name : String) : Bool :=
  match parameters with
  | List.nil => false
  | List.cons parameter rest =>
      if psStringEq parameter.name name then true else psTsSatParameterNamed rest name

def psTsSatFresh
    (fuel : Nat) (reserved : List String) (declaration : PsVerifiedIrDeclaration)
    (prefixText : String) (index : Nat) : Option PsTsFreshNameResult :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
      let name := String.Internal.append prefixText (psNatToString index);
      let used := if psIrCheckHasName reserved name then true
        else if psTsSatParameterNamed declaration.parameters name then true
        else psTsExprUsesNameWithFuel 4096 declaration.body name;
      if used then psTsSatFresh remaining reserved declaration prefixText (Nat.succ index)
      else Option.some (PsTsFreshNameResult.mk name (Nat.succ index))

def psTsSatSingleType (types : List PsVerifiedIrType) : Option PsVerifiedIrType :=
  match types with
  | List.nil => Option.none
  | List.cons type rest => if psListIsEmpty rest then Option.some type else Option.none

def psTsSatResultShape
    (type : PsVerifiedIrType) : Option (Prod (List PsVerifiedIrType) PsVerifiedIrType) :=
  match type with
  | .function firstTypes rest =>
      match psTsSatSingleType firstTypes with
      | Option.none => Option.none
      | Option.some first =>
          match rest with
          | .function secondTypes result =>
              match psTsSatSingleType secondTypes with
              | Option.none => Option.none
              | Option.some second =>
                  match result with
                  | .function _ _ => Option.none
                  | _ => Option.some (Prod.mk [first, second] result)
          | _ => Option.some (Prod.mk [first] rest)
  | _ => Option.none

def psTsSatTypeEqual (left right : PsVerifiedIrType) : Bool :=
  match psIrCheckTypeEqual 4096 left right with
  | Except.ok answer => answer
  | Except.error _ => false

def psTsSatApplyOne
    (fuel : Nat) (parameter : PsVerifiedIrParameter)
    (expectedResult : PsVerifiedIrType) (expr : PsVerifiedIrExpr) :
    Option PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Option PsVerifiedIrExpr :=
        psTsSatApplyOne remaining parameter expectedResult;
      match expr with
      | .lambda binders result body =>
          match binders with
          | List.nil => Option.none
          | List.cons bound rest =>
              if psListIsEmpty rest then
                if psTsSatTypeEqual bound.type parameter.type then
                  if psTsSatTypeEqual result expectedResult then
                    Option.some (.letE bound.name bound.type (.var parameter.name) body)
                  else Option.none
                else Option.none
              else Option.none
      | .letE name type value body =>
          if psTsSatPureWithFuel 4096 value then
            if psStringEq name parameter.name then Option.none
            else
              match smaller body with
              | Option.none => Option.none
              | Option.some next => Option.some (.letE name type value next)
          else Option.none
      | .ifE condition left right =>
          if psTsSatPureWithFuel 4096 condition then
            match smaller left with
            | Option.none => Option.none
            | Option.some first =>
                match smaller right with
                | Option.none => Option.none
                | Option.some second => Option.some (.ifE condition first second)
          else Option.none
      | _ => Option.none

def psTsSatFunctionType
    (parameters : List PsVerifiedIrParameter) (result : PsVerifiedIrType) :
    PsVerifiedIrType :=
  match parameters with
  | List.nil => result
  | List.cons parameter rest =>
      .function [parameter.type] (psTsSatFunctionType rest result)

def psTsSatApplyStages
    (parameters : List PsVerifiedIrParameter) (result : PsVerifiedIrType)
    (expr : PsVerifiedIrExpr) : Option PsVerifiedIrExpr :=
  match parameters with
  | List.nil => Option.some expr
  | List.cons parameter rest =>
      match psTsSatApplyOne 4096 parameter (psTsSatFunctionType rest result) expr with
      | Option.none => Option.none
      | Option.some next => psTsSatApplyStages rest result next

structure PsTsSatParameters where
  parameters : List PsVerifiedIrParameter
  nextIndex : Nat

def psTsSatMakeParameters
    (types : List PsVerifiedIrType) (reserved : List String)
    (declaration : PsVerifiedIrDeclaration) (index : Nat) :
    Option PsTsSatParameters :=
  match types with
  | List.nil => Option.some (PsTsSatParameters.mk List.nil index)
  | List.cons type rest =>
      match psTsSatFresh 4096 reserved declaration "__ps$stageArg$" index with
      | Option.none => Option.none
      | Option.some fresh =>
          match psTsSatMakeParameters rest (List.cons fresh.name reserved)
              declaration fresh.nextIndex with
          | Option.none => Option.none
          | Option.some tail =>
              Option.some (PsTsSatParameters.mk
                (List.cons (PsVerifiedIrParameter.mk fresh.name type) tail.parameters)
                tail.nextIndex)

structure PsTsSatCandidateResult where
  candidate : PsTsSatCandidate
  nextIndex : Nat

def psTsSatMakeCandidate
    (reserved : List String) (declaration : PsVerifiedIrDeclaration) (index : Nat) :
    Option PsTsSatCandidateResult :=
  if psListIsEmpty declaration.typeParameters then
    if psListIsEmpty declaration.parameters then Option.none
    else
      match psTsSatResultShape declaration.resultType with
      | Option.none => Option.none
      | Option.some shape =>
          match psTsSatFresh 4096 reserved declaration "__ps$stage$" index with
          | Option.none => Option.none
          | Option.some fresh =>
              match psTsSatMakeParameters shape.fst (List.cons fresh.name reserved)
                  declaration fresh.nextIndex with
              | Option.none => Option.none
              | Option.some extra =>
                  match psTsSatApplyStages extra.parameters shape.snd declaration.body with
                  | Option.none => Option.none
                  | Option.some body =>
                      let helper := PsVerifiedIrDeclaration.mk fresh.name List.nil
                        (psListAppend declaration.parameters extra.parameters) shape.snd body;
                      Option.some (PsTsSatCandidateResult.mk
                        (PsTsSatCandidate.mk declaration.name helper
                          (psListLength declaration.parameters) (psListLength extra.parameters))
                        extra.nextIndex)
  else Option.none

def psTsSatFindCandidate
    (candidates : PsErasureNameIndex PsTsSatCandidate) (name : String) :
    Option PsTsSatCandidate :=
  psErasureIndexFind PsTsSatCandidate candidates (PsName.str PsName.anonymous name)

def psTsSatSpineWithFuel
    (fuel : Nat) (expr : PsVerifiedIrExpr) (suffix : List (List PsVerifiedIrExpr)) :
    Option PsTsSatSpine :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
      match expr with
      | .call fn types arguments =>
          if psListIsEmpty types then
            match fn with
            | .var name => Option.some (PsTsSatSpine.mk name (List.cons arguments suffix))
            | _ => psTsSatSpineWithFuel remaining fn (List.cons arguments suffix)
          else Option.none
      | _ => Option.none

def psTsSatStateArguments
    (count : Nat) (groups : List (List PsVerifiedIrExpr)) :
    Option (List PsVerifiedIrExpr) :=
  match count with
  | Nat.zero => if psListIsEmpty groups then Option.some List.nil else Option.none
  | Nat.succ remaining =>
      match groups with
      | List.nil => Option.none
      | List.cons arguments rest =>
          match arguments with
          | List.nil => Option.none
          | List.cons argument more =>
              if psListIsEmpty more then
                if psTsSatPureWithFuel 4096 argument then
                  match psTsSatStateArguments remaining rest with
                  | Option.none => Option.none
                  | Option.some tail => Option.some (List.cons argument tail)
                else Option.none
              else Option.none

def psTsSatCall
    (candidates : PsErasureNameIndex PsTsSatCandidate) (locals : List String) (expr : PsVerifiedIrExpr) :
    Option (Prod String (List PsVerifiedIrExpr)) :=
  match psTsSatSpineWithFuel 4 expr List.nil with
  | Option.none => Option.none
  | Option.some spine =>
      if psIrCheckHasName locals spine.name then Option.none
      else
        match psTsSatFindCandidate candidates spine.name with
        | Option.none => Option.none
        | Option.some candidate =>
            if psIrCheckHasName locals candidate.helper.name then Option.none
            else
              match spine.groups with
              | List.nil => Option.none
              | List.cons entry rest =>
                  if Nat.beq (psListLength entry) candidate.entryArity then
                    match psTsSatStateArguments candidate.stages rest with
                    | Option.none => Option.none
                    | Option.some state =>
                        Option.some (Prod.mk candidate.helper.name (psListAppend entry state))
                  else Option.none

def psTsSatMapExpressions
    (convert : PsVerifiedIrExpr -> Option PsTsSatExprResult)
    (expressions : List PsVerifiedIrExpr) : Option PsTsSatListResult :=
  match expressions with
  | List.nil => Option.some (PsTsSatListResult.mk List.nil 0)
  | List.cons expression rest =>
      match convert expression with
      | Option.none => Option.none
      | Option.some head =>
          match psTsSatMapExpressions convert rest with
          | Option.none => Option.none
          | Option.some tail => Option.some (PsTsSatListResult.mk
              (List.cons head.expr tail.expressions) (Nat.add head.calls tail.calls))

def psTsSatMapFields
    (convert : PsVerifiedIrExpr -> Option PsTsSatExprResult)
    (fields : List (Prod String PsVerifiedIrExpr)) : Option PsTsSatFieldsResult :=
  match fields with
  | List.nil => Option.some (PsTsSatFieldsResult.mk List.nil 0)
  | List.cons field rest =>
      match convert field.snd with
      | Option.none => Option.none
      | Option.some head =>
          match psTsSatMapFields convert rest with
          | Option.none => Option.none
          | Option.some tail => Option.some (PsTsSatFieldsResult.mk
              (List.cons (Prod.mk field.fst head.expr) tail.fields) (Nat.add head.calls tail.calls))

def psTsSatParameterNames
    (parameters : List PsVerifiedIrParameter) : List String :=
  psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.name) parameters

def psTsSatBindingNames
    (bindings : List PsVerifiedIrMatchBinding) : List String :=
  psListMap (fun (binding : PsVerifiedIrMatchBinding) => binding.name) bindings

def psTsSatMapAlternatives
    (convert : List PsVerifiedIrMatchBinding -> PsVerifiedIrExpr -> Option PsTsSatExprResult)
    (alternatives : List
      (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) :
    Option PsTsSatAlternativesResult :=
  match alternatives with
  | List.nil => Option.some (PsTsSatAlternativesResult.mk List.nil 0)
  | List.cons alternative rest =>
      match convert alternative.snd.fst alternative.snd.snd with
      | Option.none => Option.none
      | Option.some head =>
          match psTsSatMapAlternatives convert rest with
          | Option.none => Option.none
          | Option.some tail => Option.some (PsTsSatAlternativesResult.mk
              (List.cons (Prod.mk alternative.fst
                (Prod.mk alternative.snd.fst head.expr)) tail.alternatives)
              (Nat.add head.calls tail.calls))

def psTsSatRewrite
    (fuel : Nat) (candidates : PsErasureNameIndex PsTsSatCandidate)
    (locals : List String) (expr : PsVerifiedIrExpr) : Option PsTsSatExprResult :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Option PsTsSatExprResult :=
        psTsSatRewrite remaining candidates locals;
      match psTsSatCall candidates locals expr with
      | Option.some call =>
          match psTsSatMapExpressions smaller call.snd with
          | Option.none => Option.none
          | Option.some arguments => Option.some (PsTsSatExprResult.mk
              (.call (.var call.fst) List.nil arguments.expressions)
              (Nat.succ arguments.calls))
      | Option.none =>
          match expr with
          | .literal _ => Option.some (PsTsSatExprResult.mk expr 0)
          | .var _ => Option.some (PsTsSatExprResult.mk expr 0)
          | .intrinsic operation types arguments =>
              match psTsSatMapExpressions smaller arguments with
              | Option.none => Option.none
              | Option.some result => Option.some (PsTsSatExprResult.mk
                  (.intrinsic operation types result.expressions) result.calls)
          | .lambda parameters result body =>
              match psTsSatRewrite remaining candidates
                  (psListAppend (psTsSatParameterNames parameters) locals) body with
              | Option.none => Option.none
              | Option.some next => Option.some (PsTsSatExprResult.mk
                  (.lambda parameters result next.expr) next.calls)
          | .call fn types arguments =>
              match smaller fn with
              | Option.none => Option.none
              | Option.some target =>
                  match psTsSatMapExpressions smaller arguments with
                  | Option.none => Option.none
                  | Option.some values => Option.some (PsTsSatExprResult.mk
                      (.call target.expr types values.expressions)
                      (Nat.add target.calls values.calls))
          | .letE name type value body =>
              match smaller value with
              | Option.none => Option.none
              | Option.some first =>
                  match psTsSatRewrite remaining candidates (List.cons name locals) body with
                  | Option.none => Option.none
                  | Option.some second => Option.some (PsTsSatExprResult.mk
                      (.letE name type first.expr second.expr) (Nat.add first.calls second.calls))
          | .ifE condition left right =>
              match smaller condition with
              | Option.none => Option.none
              | Option.some test =>
                  match smaller left with
                  | Option.none => Option.none
                  | Option.some first =>
                      match smaller right with
                      | Option.none => Option.none
                      | Option.some second => Option.some (PsTsSatExprResult.mk
                          (.ifE test.expr first.expr second.expr)
                          (Nat.add test.calls (Nat.add first.calls second.calls)))
          | .record name types fields =>
              match psTsSatMapFields smaller fields with
              | Option.none => Option.none
              | Option.some result => Option.some (PsTsSatExprResult.mk
                  (.record name types result.fields) result.calls)
          | .projection name types target field =>
              match smaller target with
              | Option.none => Option.none
              | Option.some result => Option.some (PsTsSatExprResult.mk
                  (.projection name types result.expr field) result.calls)
          | .constructor name constructor types fields =>
              match psTsSatMapFields smaller fields with
              | Option.none => Option.none
              | Option.some result => Option.some (PsTsSatExprResult.mk
                  (.constructor name constructor types result.fields) result.calls)
          | .matchE name types scrutinee alternatives =>
              match smaller scrutinee with
              | Option.none => Option.none
              | Option.some target =>
                  let convert : List PsVerifiedIrMatchBinding -> PsVerifiedIrExpr ->
                      Option PsTsSatExprResult :=
                    fun (bindings : List PsVerifiedIrMatchBinding) (body : PsVerifiedIrExpr) => psTsSatRewrite remaining candidates
                      (psListAppend (psTsSatBindingNames bindings) locals) body;
                  match psTsSatMapAlternatives convert alternatives with
                  | Option.none => Option.none
                  | Option.some branches => Option.some (PsTsSatExprResult.mk
                      (.matchE name types target.expr branches.alternatives)
                      (Nat.add target.calls branches.calls))

structure PsTsSatCollection where
  candidates : PsErasureNameIndex PsTsSatCandidate
  privateNames : List String
  nextIndex : Nat

def psTsSatInsertCandidate
    (candidates : PsErasureNameIndex PsTsSatCandidate) (candidate : PsTsSatCandidate) :
    PsErasureNameIndex PsTsSatCandidate :=
  psErasureIndexInsert PsTsSatCandidate candidates
    (PsName.str PsName.anonymous candidate.sourceName) candidate

/- A helper precedes its original entry. A remaining partial self reference
   would therefore read a later declaration. Keep such functions entirely on
   the original path. Requiring a rewritten self call also avoids duplicating
   arbitrary nonrecursive function-returning declarations. -/
def psTsSatSelfEligible (candidate : PsTsSatCandidate) : Bool :=
  let own := psTsSatInsertCandidate PsErasureNameIndex.empty candidate;
  match psTsSatRewrite 4096 own
      (psTsSatParameterNames candidate.helper.parameters) candidate.helper.body with
  | Option.none => false
  | Option.some result =>
      if Nat.beq result.calls 0 then false
      else if psTsExprUsesNameWithFuel 4096 result.expr candidate.sourceName then false
      else true

def psTsSatCollect
    (declarations : List PsVerifiedIrDeclaration) (reserved : List String)
    (state : PsTsSatCollection) : PsTsSatCollection :=
  match declarations with
  | List.nil => state
  | List.cons declaration rest =>
      match psTsSatMakeCandidate reserved declaration state.nextIndex with
      | Option.none => psTsSatCollect rest reserved state
      | Option.some found =>
          if psTsSatSelfEligible found.candidate then
            let name := found.candidate.helper.name;
            let next := PsTsSatCollection.mk
              (psTsSatInsertCandidate state.candidates found.candidate)
              (List.cons name state.privateNames) found.nextIndex;
            psTsSatCollect rest (List.cons name reserved) next
          else psTsSatCollect rest reserved
            (PsTsSatCollection.mk state.candidates state.privateNames found.nextIndex)

structure PsTsSatDeclarations where
  declarations : List PsVerifiedIrDeclaration
  calls : Nat

def psTsSatRewriteDeclaration
    (candidates : PsErasureNameIndex PsTsSatCandidate)
    (declaration : PsVerifiedIrDeclaration) :
    Option (Prod PsVerifiedIrDeclaration Nat) :=
  match psTsSatRewrite 4096 candidates
      (psTsSatParameterNames declaration.parameters) declaration.body with
  | Option.none => Option.none
  | Option.some result => Option.some (Prod.mk
      (PsVerifiedIrDeclaration.mk declaration.name declaration.typeParameters
        declaration.parameters declaration.resultType result.expr) result.calls)

def psTsSatRewriteDeclarations
    (candidates : PsErasureNameIndex PsTsSatCandidate)
    (declarations : List PsVerifiedIrDeclaration) : Option PsTsSatDeclarations :=
  match declarations with
  | List.nil => Option.some (PsTsSatDeclarations.mk List.nil 0)
  | List.cons declaration rest =>
      match psTsSatRewriteDeclaration candidates declaration with
      | Option.none => Option.none
      | Option.some current =>
          match psTsSatRewriteDeclarations candidates rest with
          | Option.none => Option.none
          | Option.some tail =>
              match psTsSatFindCandidate candidates declaration.name with
              | Option.none => Option.some (PsTsSatDeclarations.mk
                  (List.cons current.fst tail.declarations) (Nat.add current.snd tail.calls))
              | Option.some candidate =>
                  match psTsSatRewriteDeclaration candidates candidate.helper with
                  | Option.none => Option.none
                  | Option.some helper => Option.some (PsTsSatDeclarations.mk
                      (List.cons helper.fst (List.cons current.fst tail.declarations))
                      (Nat.add helper.snd (Nat.add current.snd tail.calls)))

def psTsSatBuildPlan (module : PsVerifiedIrModule) : Option PsTsSatPlan :=
  let collected := psTsSatCollect module.declarations (psTsModuleTopLevelNames module)
    (PsTsSatCollection.mk PsErasureNameIndex.empty List.nil 0);
  if psListIsEmpty collected.privateNames then Option.none
  else
    match psTsSatRewriteDeclarations collected.candidates module.declarations with
    | Option.none => Option.none
    | Option.some result =>
        if Nat.beq result.calls 0 then Option.none
        else Option.some (PsTsSatPlan.mk
          (PsVerifiedIrModule.mk module.imports module.structures module.inductives result.declarations)
          collected.privateNames (psListLength collected.privateNames) result.calls)

/- Helpers use the existing generator runtime and are emitted without export.
   They are interleaved immediately before the original entry. Original
   entry signatures and staged lambda structure remain. Only qualified saturated
   call sites inside their bodies use a private helper. -/
def psTsSatEmitPrivate
    (brands tags : List (Prod String String))
    (declaration : PsVerifiedIrDeclaration) : Except PsTsEmitError String :=
  if psListIsEmpty declaration.typeParameters then
    match psTsEmitType declaration.resultType with
    | Except.error error => Except.error error
    | Except.ok resultType =>
        let printParameter : PsVerifiedIrParameter -> Except PsTsEmitError String :=
          fun (parameter : PsVerifiedIrParameter) =>
            match psTsEmitType parameter.type with
            | Except.error error => Except.error error
            | Except.ok type => Except.ok (psTsJoin "" [parameter.name, ": ", type]);
        match psListMapExcept printParameter declaration.parameters with
        | Except.error error => Except.error error
        | Except.ok parameters =>
            match psTsEmitExpr brands tags (psTsInlineEtaApplication declaration.body) with
            | Except.error error => Except.error error
            | Except.ok body => Except.ok
                (psTsJoin "" ["const ", declaration.name, " = __ps$wrap(function*(",
                  psTsJoin ", " parameters, "): __ps$Computation<", resultType,
                  "> { return ", body, "; });"])
  else Except.error (PsTsEmitError.genericValueUnsupported declaration.name)

def psTsSatEmitPlan (plan : PsTsSatPlan) : Except PsTsEmitError String :=
  let module := plan.module;
  let brands := psTsBuildBrandMap module;
  let tags := psTsBuildTagMap module;
  match psListMapExcept (psTsEmitStructure brands) module.structures with
  | Except.error error => Except.error error
  | Except.ok structures =>
      match psListMapExcept (psTsEmitInductive tags) module.inductives with
      | Except.error error => Except.error error
      | Except.ok inductives =>
          let emit : PsVerifiedIrDeclaration -> Except PsTsEmitError String :=
            fun (declaration : PsVerifiedIrDeclaration) =>
              if psIrCheckHasName plan.privateNames declaration.name then
                psTsSatEmitPrivate brands tags declaration
              else psTsEmitDeclaration brands tags declaration;
          match psListMapExcept emit module.declarations with
          | Except.error error => Except.error error
          | Except.ok declarations =>
              let header : List String :=
                ["// generated from pskernel-admitted ProofScript checked core", psTsRuntimeSupport];
              let lines := psTsFlattenLines [header, psListMap psTsEmitImport module.imports,
                psTsFlattenLines structures, psTsFlattenLines inductives, declarations];
              Except.ok (psTsJoin "" [psTsJoin "\n" lines, "\n"])

structure PsTsSatEmission where
  originalReport : PsIrCheckReport
  originalTarget : Option PsSh1TargetReport
  candidateReport : Option PsIrCheckReport
  candidateTarget : Option PsSh1TargetReport
  typeScript : String
  optimized : Bool
  reason : String
  helperCount : Nat
  rewrittenCalls : Nat

def psTsSatFallback
    (ir : PsVerifiedIrModule) (report : PsIrCheckReport)
    (originalTarget : Option PsSh1TargetReport) (candidateReport : Option PsIrCheckReport)
    (candidateTarget : Option PsSh1TargetReport) (reason : String) :
    Except PsTsCheckedEmitError PsTsSatEmission :=
  match psTsEmitModule ir with
  | Except.error error => Except.error (PsTsCheckedEmitError.emit error)
  | Except.ok output => Except.ok (PsTsSatEmission.mk report originalTarget
      candidateReport candidateTarget output false reason 0 0)

/- The only checked optimization entry owns both checks and the exact plan.
   Externally constructed reports, helper maps or transformed modules are never
   accepted as authorization. Defaults and resource policies are unchanged. -/
def psTsEmitSaturatedCheckedModule
    (options : PsIrCheckOptions) (ir : PsVerifiedIrModule) :
    Except PsTsCheckedEmitError PsTsSatEmission :=
  match psTsCheckModuleForEmission options ir with
  | Except.error error => Except.error error
  | Except.ok originalReport =>
      match psSh1CheckTarget options.maxSteps ir with
      | Except.error error =>
          psTsSatFallback ir originalReport Option.none Option.none Option.none
            (String.Internal.append "original-target:" error.code)
      | Except.ok originalTarget =>
          if if originalTarget.accepted then originalTarget.traversalComplete else false then
            match psTsSatBuildPlan ir with
            | Option.none =>
                psTsSatFallback ir originalReport (Option.some originalTarget)
                  Option.none Option.none "no-eligible-plan"
            | Option.some plan =>
                let candidateReport := psCheckVerifiedIrModule options plan.module;
                if if candidateReport.accepted then candidateReport.traversalComplete else false then
                  match psSh1CheckTarget options.maxSteps plan.module with
                  | Except.error error =>
                      psTsSatFallback ir originalReport (Option.some originalTarget)
                        (Option.some candidateReport) Option.none
                        (String.Internal.append "candidate-target:" error.code)
                  | Except.ok candidateTarget =>
                      if if candidateTarget.accepted then candidateTarget.traversalComplete else false then
                        match psTsSatEmitPlan plan with
                        | Except.error _ =>
                            psTsSatFallback ir originalReport (Option.some originalTarget)
                              (Option.some candidateReport) (Option.some candidateTarget)
                              "candidate-emission"
                        | Except.ok output =>
                            Except.ok (PsTsSatEmission.mk originalReport
                              (Option.some originalTarget) (Option.some candidateReport)
                              (Option.some candidateTarget) output true "checked-saturation"
                              plan.helperCount plan.rewrittenCalls)
                      else psTsSatFallback ir originalReport (Option.some originalTarget)
                        (Option.some candidateReport) (Option.some candidateTarget)
                        "candidate-target-incomplete"
                else psTsSatFallback ir originalReport (Option.some originalTarget)
                  (Option.some candidateReport) Option.none "candidate-IR-check"
          else psTsSatFallback ir originalReport (Option.some originalTarget)
            Option.none Option.none "original-target-incomplete"

def psCompilerSaturatedTypeScriptFromPrepared
    (options : PsIrCheckOptions) (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerCheckedTypeScriptError PsTsSatEmission :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error => Except.error (PsCompilerCheckedTypeScriptError.compiler error)
  | Except.ok ir =>
      match psTsEmitSaturatedCheckedModule options ir with
      | Except.error error => Except.error (PsCompilerCheckedTypeScriptError.checkedEmit error)
      | Except.ok output => Except.ok output

