import Ps.TheoryBridge.Model
import Ps.Core.Declaration
import Ps.Core.Equality
import Ps.Foundation.List

structure PsTheoryCoreSymbolMap where
  source : PsName
  destination : PsName

structure PsTheoryCoreView where
  theoryId : String
  semanticProfile : String
  declarations : List PsDeclaration

structure PsTheoryTranslationPlan where
  contract : String
  sourceTheoryId : String
  destinationTheoryId : String
  symbols : List PsTheoryCoreSymbolMap
  axioms : List PsTheoryCoreSymbolMap
  allowedSourceAxioms : List PsName
  allowedDestinationAxioms : List PsName
  unsupportedFeatures : List String

inductive PsTheoryTranslationError where
  | invalidContext
  | unsupportedFeature
  | invalidMap
  | missingSymbol (name : PsName)
  | unboundVariable
  | invalidUniverse
  | assumptionDenied (name : PsName)
  | declarationMismatch (name : PsName)

-- This result establishes a checked syntactic relation only. Both theories
-- still require independent kernel acceptance; global preservation is unproved.
structure PsTheoryTranslationResult where
  sourceTheoryId : String
  destinationTheoryId : String
  semanticProfile : String
  translated : List PsDeclaration
  relation : String
  preservation : String

def psTheoryNameIn (name : PsName) (names : List PsName) : Bool :=
  match names with
  | List.nil => false
  | List.cons other rest =>
      if psNameEq name other then true else psTheoryNameIn name rest

def psTheoryNamesUnique (names : List PsName) : Bool :=
  match names with
  | List.nil => true
  | List.cons name rest =>
      if psNameEq name PsName.anonymous then false
      else if psTheoryNameIn name rest then false
      else psTheoryNamesUnique rest

def psTheoryAll {alpha : Type} (check : alpha -> Bool) (values : List alpha) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if check value then psTheoryAll check rest else false

def psTheoryMapSource (entry : PsTheoryCoreSymbolMap) : PsName := entry.source

def psTheoryMapDestination (entry : PsTheoryCoreSymbolMap) : PsName := entry.destination

def psTheoryFindMapping (entries : List PsTheoryCoreSymbolMap) (name : PsName) :
    Except PsTheoryTranslationError PsName :=
  match entries with
  | List.nil => Except.error (PsTheoryTranslationError.missingSymbol name)
  | List.cons entry rest =>
      if psNameEq entry.source name then Except.ok entry.destination
      else psTheoryFindMapping rest name

def psTheoryDeclarationName (declaration : PsDeclaration) : PsName :=
  match declaration with
  | .axiomDecl name _ _ => name
  | .definitionDecl name _ _ _ => name
  | .theoremDecl name _ _ _ => name
  | .partialDecl name _ _ _ => name
  | .opaqueDecl name _ _ _ => name
  | .inductiveDecl info => info.name
  | .constructorDecl info => info.name
  | .recursorDecl info => info.name

def psTheoryDeclarationSupported (declaration : PsDeclaration) : Bool :=
  match declaration with
  | .axiomDecl _ _ _ => true
  | .definitionDecl _ _ _ _ => true
  | .theoremDecl _ _ _ _ => true
  | _ => false

def psTheoryFindDeclaration (declarations : List PsDeclaration) (name : PsName) :
    Option PsDeclaration :=
  match declarations with
  | List.nil => Option.none
  | List.cons declaration rest =>
      if psNameEq name (psTheoryDeclarationName declaration) then Option.some declaration
      else psTheoryFindDeclaration rest name

def psTheoryLevelValid (level : PsLevel) : List PsName -> Bool :=
  match level with
  | .zero => fun (_parameters : List PsName) => true
  | .succ of =>
      let smaller : List PsName -> Bool := psTheoryLevelValid of;
      fun (parameters : List PsName) => smaller parameters
  | .max left right =>
      let leftCheck : List PsName -> Bool := psTheoryLevelValid left;
      let rightCheck : List PsName -> Bool := psTheoryLevelValid right;
      fun (parameters : List PsName) => if leftCheck parameters then rightCheck parameters else false
  | .imax left right =>
      let leftCheck : List PsName -> Bool := psTheoryLevelValid left;
      let rightCheck : List PsName -> Bool := psTheoryLevelValid right;
      fun (parameters : List PsName) => if leftCheck parameters then rightCheck parameters else false
  | .param name => fun (parameters : List PsName) => psTheoryNameIn name parameters
  | .mvar _ => fun (_parameters : List PsName) => false

def psTheoryTranslateExpr (expression : PsExpr) : List PsTheoryCoreSymbolMap -> List PsName -> Nat ->
    Except PsTheoryTranslationError PsExpr :=
  match expression with
  | .bvar index =>
      fun (_symbols : List PsTheoryCoreSymbolMap) (_parameters : List PsName) (depth : Nat) =>
        if Nat.blt index depth then Except.ok (PsExpr.bvar index)
        else Except.error PsTheoryTranslationError.unboundVariable
  | .fvar _ =>
      fun (_symbols : List PsTheoryCoreSymbolMap) (_parameters : List PsName) (_depth : Nat) =>
        Except.error PsTheoryTranslationError.unboundVariable
  | .mvar _ =>
      fun (_symbols : List PsTheoryCoreSymbolMap) (_parameters : List PsName) (_depth : Nat) =>
        Except.error PsTheoryTranslationError.unboundVariable
  | .sortE level =>
      fun (_symbols : List PsTheoryCoreSymbolMap) (parameters : List PsName) (_depth : Nat) =>
        if psTheoryLevelValid level parameters then Except.ok (PsExpr.sortE level)
        else Except.error PsTheoryTranslationError.invalidUniverse
  | .constE name levels =>
      fun (symbols : List PsTheoryCoreSymbolMap) (parameters : List PsName) (_depth : Nat) =>
        let check : PsLevel -> Bool := fun (level : PsLevel) => psTheoryLevelValid level parameters;
        if psTheoryAll check levels then
          match psTheoryFindMapping symbols name with
          | Except.error error => Except.error error
          | Except.ok target => Except.ok (PsExpr.constE target levels)
        else Except.error PsTheoryTranslationError.invalidUniverse
  | .app fn arg =>
      let fnTranslate := psTheoryTranslateExpr fn;
      let argTranslate := psTheoryTranslateExpr arg;
      fun (symbols : List PsTheoryCoreSymbolMap) (parameters : List PsName) (depth : Nat) =>
        match fnTranslate symbols parameters depth with
        | Except.error error => Except.error error
        | Except.ok targetFn =>
            match argTranslate symbols parameters depth with
            | Except.error error => Except.error error
            | Except.ok targetArg => Except.ok (PsExpr.app targetFn targetArg)
  | .lam name type body binder =>
      let typeTranslate := psTheoryTranslateExpr type;
      let bodyTranslate := psTheoryTranslateExpr body;
      fun (symbols : List PsTheoryCoreSymbolMap) (parameters : List PsName) (depth : Nat) =>
        match typeTranslate symbols parameters depth with
        | Except.error error => Except.error error
        | Except.ok targetType =>
            match bodyTranslate symbols parameters (Nat.succ depth) with
            | Except.error error => Except.error error
            | Except.ok targetBody => Except.ok (PsExpr.lam name targetType targetBody binder)
  | .forallE name type body binder =>
      let typeTranslate := psTheoryTranslateExpr type;
      let bodyTranslate := psTheoryTranslateExpr body;
      fun (symbols : List PsTheoryCoreSymbolMap) (parameters : List PsName) (depth : Nat) =>
        match typeTranslate symbols parameters depth with
        | Except.error error => Except.error error
        | Except.ok targetType =>
            match bodyTranslate symbols parameters (Nat.succ depth) with
            | Except.error error => Except.error error
            | Except.ok targetBody => Except.ok (PsExpr.forallE name targetType targetBody binder)
  | .letE name type value body =>
      let typeTranslate := psTheoryTranslateExpr type;
      let valueTranslate := psTheoryTranslateExpr value;
      let bodyTranslate := psTheoryTranslateExpr body;
      fun (symbols : List PsTheoryCoreSymbolMap) (parameters : List PsName) (depth : Nat) =>
        match typeTranslate symbols parameters depth with
        | Except.error error => Except.error error
        | Except.ok targetType =>
            match valueTranslate symbols parameters depth with
            | Except.error error => Except.error error
            | Except.ok targetValue =>
                match bodyTranslate symbols parameters (Nat.succ depth) with
                | Except.error error => Except.error error
                | Except.ok targetBody => Except.ok (PsExpr.letE name targetType targetValue targetBody)
  | .lit literal =>
      fun (_symbols : List PsTheoryCoreSymbolMap) (_parameters : List PsName) (_depth : Nat) =>
        Except.ok (PsExpr.lit literal)
  | .proj _ _ _ =>
      fun (_symbols : List PsTheoryCoreSymbolMap) (_parameters : List PsName) (_depth : Nat) =>
        Except.error PsTheoryTranslationError.unsupportedFeature

def psTheoryTranslateHeader (symbols : List PsTheoryCoreSymbolMap) (name : PsName)
    (parameters : List PsName) (type : PsExpr) :
    Except PsTheoryTranslationError (Prod PsName PsExpr) :=
  if psTheoryNamesUnique parameters then
    match psTheoryFindMapping symbols name with
    | Except.error error => Except.error error
    | Except.ok targetName =>
        match psTheoryTranslateExpr type symbols parameters 0 with
        | Except.error error => Except.error error
        | Except.ok targetType => Except.ok (Prod.mk targetName targetType)
  else Except.error PsTheoryTranslationError.invalidUniverse

def psTheoryTranslateDeclaration (symbols : List PsTheoryCoreSymbolMap) (declaration : PsDeclaration) :
    Except PsTheoryTranslationError PsDeclaration :=
  match declaration with
  | .axiomDecl name parameters type =>
      match psTheoryTranslateHeader symbols name parameters type with
      | Except.error error => Except.error error
      | Except.ok header => Except.ok (PsDeclaration.axiomDecl header.fst parameters header.snd)
  | .definitionDecl name parameters type value =>
      match psTheoryTranslateHeader symbols name parameters type with
      | Except.error error => Except.error error
      | Except.ok header =>
          match psTheoryTranslateExpr value symbols parameters 0 with
          | Except.error error => Except.error error
          | Except.ok targetValue => Except.ok (PsDeclaration.definitionDecl header.fst parameters header.snd targetValue)
  | .theoremDecl name parameters type value =>
      match psTheoryTranslateHeader symbols name parameters type with
      | Except.error error => Except.error error
      | Except.ok header =>
          match psTheoryTranslateExpr value symbols parameters 0 with
          | Except.error error => Except.error error
          | Except.ok targetValue => Except.ok (PsDeclaration.theoremDecl header.fst parameters header.snd targetValue)
  | _ => Except.error PsTheoryTranslationError.unsupportedFeature

def psTheoryNameListEq (left : List PsName) : List PsName -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsName) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons name rest =>
      let smaller : List PsName -> Bool := psTheoryNameListEq rest;
      fun (right : List PsName) =>
        match right with
        | List.nil => false
        | List.cons other others => if psNameEq name other then smaller others else false

def psTheoryDeclarationEq (left right : PsDeclaration) : Bool :=
  match left with
  | .axiomDecl name parameters type =>
      match right with
      | .axiomDecl other otherParameters otherType =>
          if psNameEq name other then
            if psTheoryNameListEq parameters otherParameters then psExprAlphaEq type otherType else false
          else false
      | _ => false
  | .definitionDecl name parameters type value =>
      match right with
      | .definitionDecl other otherParameters otherType otherValue =>
          if psNameEq name other then
            if psTheoryNameListEq parameters otherParameters then
              if psExprAlphaEq type otherType then psExprAlphaEq value otherValue else false
            else false
          else false
      | _ => false
  | .theoremDecl name parameters type value =>
      match right with
      | .theoremDecl other otherParameters otherType otherValue =>
          if psNameEq name other then
            if psTheoryNameListEq parameters otherParameters then
              if psExprAlphaEq type otherType then psExprAlphaEq value otherValue else false
            else false
          else false
      | _ => false
  | _ => false

def psTheoryAxiomNames (declarations : List PsDeclaration) : List PsName :=
  match declarations with
  | List.nil => List.nil
  | List.cons declaration rest =>
      let smaller := psTheoryAxiomNames rest;
      match declaration with
      | .axiomDecl name _ _ => List.cons name smaller
      | _ => smaller

def psTheoryNamesSameSet (left right : List PsName) : Bool :=
  let check : PsName -> Bool := fun (name : PsName) => psTheoryNameIn name right;
  if Nat.beq (psListLength left) (psListLength right) then
    if psTheoryNamesUnique left then
      if psTheoryNamesUnique right then psTheoryAll check left else false
    else false
  else false

def psTheoryMapAgrees (symbols : List PsTheoryCoreSymbolMap) (entry : PsTheoryCoreSymbolMap) : Bool :=
  match psTheoryFindMapping symbols entry.source with
  | Except.error _ => false
  | Except.ok target => psNameEq target entry.destination

def psTheoryCheckAllowedAxioms (allowed names : List PsName) : Except PsTheoryTranslationError Unit :=
  match names with
  | List.nil => Except.ok Unit.unit
  | List.cons name rest =>
      if psTheoryNameIn name allowed then psTheoryCheckAllowedAxioms allowed rest
      else Except.error (PsTheoryTranslationError.assumptionDenied name)

def psTheoryCheckDeclarationMatch (destination : List PsDeclaration) (declaration : PsDeclaration) :
    Except PsTheoryTranslationError Unit :=
  let name := psTheoryDeclarationName declaration;
  match psTheoryFindDeclaration destination name with
  | Option.none => Except.error (PsTheoryTranslationError.missingSymbol name)
  | Option.some target =>
      if psTheoryDeclarationEq declaration target then Except.ok Unit.unit
      else Except.error (PsTheoryTranslationError.declarationMismatch name)

def psTheoryTranslationMapValid (plan : PsTheoryTranslationPlan) (source destination : PsTheoryCoreView) : Bool :=
  if psTheoryNamesSameSet (psListMap psTheoryMapSource plan.symbols) (psListMap psTheoryDeclarationName source.declarations) then
    if psTheoryNamesSameSet (psListMap psTheoryMapDestination plan.symbols) (psListMap psTheoryDeclarationName destination.declarations) then
      if psTheoryNamesSameSet (psListMap psTheoryMapSource plan.axioms) (psTheoryAxiomNames source.declarations) then
        if psTheoryNamesSameSet (psListMap psTheoryMapDestination plan.axioms) (psTheoryAxiomNames destination.declarations) then
          psTheoryAll (psTheoryMapAgrees plan.symbols) plan.axioms
        else false
      else false
    else false
  else false

def psTheoryCheckTranslationBody (plan : PsTheoryTranslationPlan) (source destination : PsTheoryCoreView) :
    Except PsTheoryTranslationError PsTheoryTranslationResult :=
  if psTheoryTranslationMapValid plan source destination then
    match psTheoryCheckAllowedAxioms plan.allowedSourceAxioms (psTheoryAxiomNames source.declarations) with
    | Except.error error => Except.error error
    | Except.ok _ =>
        match psTheoryCheckAllowedAxioms plan.allowedDestinationAxioms (psTheoryAxiomNames destination.declarations) with
        | Except.error error => Except.error error
        | Except.ok _ =>
            match psListMapExcept (psTheoryTranslateDeclaration plan.symbols) source.declarations with
            | Except.error error => Except.error error
            | Except.ok translated =>
                match psListMapExcept (psTheoryCheckDeclarationMatch destination.declarations) translated with
                | Except.error error => Except.error error
                | Except.ok _ => Except.ok (PsTheoryTranslationResult.mk source.theoryId destination.theoryId source.semanticProfile translated "closed-core-renaming-checked" "global-preservation-unproved")
  else Except.error PsTheoryTranslationError.invalidMap

def psTheoryCheckTranslation (plan : PsTheoryTranslationPlan) (source destination : PsTheoryCoreView) :
    Except PsTheoryTranslationError PsTheoryTranslationResult :=
  if psStringEq plan.contract "psc-core-renaming/1" then
    if psStringEq source.theoryId "" then Except.error PsTheoryTranslationError.invalidContext
    else if psStringEq destination.theoryId "" then Except.error PsTheoryTranslationError.invalidContext
    else if psStringEq source.semanticProfile "" then Except.error PsTheoryTranslationError.invalidContext
    else if psStringEq plan.sourceTheoryId source.theoryId then
      if psStringEq plan.destinationTheoryId destination.theoryId then
        if psStringEq source.semanticProfile destination.semanticProfile then
          match plan.unsupportedFeatures with
          | List.cons _ _ => Except.error PsTheoryTranslationError.unsupportedFeature
          | List.nil =>
              if psTheoryAll psTheoryDeclarationSupported source.declarations then
                if psTheoryAll psTheoryDeclarationSupported destination.declarations then
                  psTheoryCheckTranslationBody plan source destination
                else Except.error PsTheoryTranslationError.unsupportedFeature
              else Except.error PsTheoryTranslationError.unsupportedFeature
        else Except.error PsTheoryTranslationError.unsupportedFeature
      else Except.error PsTheoryTranslationError.invalidContext
    else Except.error PsTheoryTranslationError.invalidContext
  else Except.error PsTheoryTranslationError.unsupportedFeature
