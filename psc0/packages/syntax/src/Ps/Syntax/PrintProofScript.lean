import Ps.Syntax.PrintCommon

def psPrintProofScriptBoolNot (value : Bool) : Bool :=
  if value then false else true

def psPrintProofScriptConcat2
    (a b : String) : String :=
  String.Internal.append a b

def psPrintProofScriptConcat3
    (a b c : String) : String :=
  let ab := psPrintProofScriptConcat2 a b;
  psPrintProofScriptConcat2 ab c

def psPrintProofScriptConcat4
    (a b c d : String) : String :=
  let abc := psPrintProofScriptConcat3 a b c;
  psPrintProofScriptConcat2 abc d

def psPrintProofScriptConcat5
    (a b c d e : String) : String :=
  let abcd := psPrintProofScriptConcat4 a b c d;
  psPrintProofScriptConcat2 abcd e

def psPrintProofScriptConcat6
    (a b c d e f : String) : String :=
  let abcde := psPrintProofScriptConcat5 a b c d e;
  psPrintProofScriptConcat2 abcde f

-- Group complex terms before using them as postfix callees or arguments.
-- Parentheses preserve application groups without changing the owned AST.
def psPrintProofScriptGroupedTerm
    (term : PsSyntaxTerm) (printed : String) : String :=
  if psSyntaxTermSimpleForApplication term then printed
  else psPrintProofScriptConcat3 "(" printed ")"

def psPrintProofScriptMapRecordFields
    (printField :
      Prod PsSyntaxName PsSyntaxTerm ->
        Except PsSourcePrintError String)
    (fields : List (Prod PsSyntaxName PsSyntaxTerm)) :
    Except PsSourcePrintError (List String) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      let printedHeadResult :=
        printField field;
      match printedHeadResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedHead =>
          let printedTailResult :=
            psPrintProofScriptMapRecordFields printField rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintProofScriptMapTerms
    (printTerm :
      PsSyntaxTerm -> Except PsSourcePrintError String)
    (terms : List PsSyntaxTerm) :
    Except PsSourcePrintError (List String) :=
  match terms with
  | List.nil =>
      Except.ok List.nil
  | List.cons term rest =>
      let printedHeadResult :=
        printTerm term;
      match printedHeadResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedHead =>
          let printedTailResult :=
            psPrintProofScriptMapTerms printTerm rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintProofScriptMapBinders
    (printBinder :
      Prod PsSyntaxBinderHead PsSyntaxTerm ->
        Except PsSourcePrintError String)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsSourcePrintError (List String) :=
  match binders with
  | List.nil =>
      Except.ok List.nil
  | List.cons binder rest =>
      let printedHeadResult :=
        printBinder binder;
      match printedHeadResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedHead =>
          let printedTailResult :=
            psPrintProofScriptMapBinders printBinder rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintProofScriptMapAlternatives
    (printAlternative :
      Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan) ->
        Except PsSourcePrintError String)
    (alternatives :
      List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) :
    Except PsSourcePrintError (List String) :=
  match alternatives with
  | List.nil =>
      Except.ok List.nil
  | List.cons alternative rest =>
      let printedHeadResult :=
        printAlternative alternative;
      match printedHeadResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedHead =>
          let printedTailResult :=
            psPrintProofScriptMapAlternatives printAlternative rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintProofScriptTermWithFuel
    (fuel : Nat) :
    PsSyntaxTerm -> Except PsSourcePrintError String :=
  match fuel with
  | 0 =>
      fun (_term : PsSyntaxTerm) =>
        Except.error PsSourcePrintError.fuelExhausted
  | remaining + 1 =>
      fun (term : PsSyntaxTerm) =>
      let smaller :
          PsSyntaxTerm -> Except PsSourcePrintError String :=
        psPrintProofScriptTermWithFuel remaining;
      match term with
      | .hole _ => Except.ok "_"
      | .omittedType _ => Except.error (.unsupportedSourceForm "omitted result annotation outside a declaration")
      | .optionalType type value _ => do
          let type ← smaller type
          let value ← smaller value
          return type ++ " := " ++ value
      | .ascription value type _ => do
          let value ← smaller value
          let type ← smaller type
          return "(" ++ value ++ " : " ++ type ++ ")"
      | .operatorE kind _ spelling arguments _ => do
          psPrintSyntaxOperator kind spelling (← arguments.mapM smaller)
      | .call placement fn args _ => do
          if placement == .namedPriority && args.any (·.fst.isSome) && args.any (·.fst.isNone) then
            throw (.unsupportedSourceForm "mixed native named application requires typed source reconstruction")
          let head ← smaller fn
          let arguments ← args.mapM fun (label, value) => do
            let value ← smaller value
            match label with
            | none => pure value
            | some name =>
              let name ← psPrintSyntaxName name
              pure (name ++ " := " ++ value)
          let head := if psSyntaxTermSimpleForApplication fn then head else "(" ++ head ++ ")"
          return head ++ "(" ++ psPrintJoin ", " arguments ++ ")"
      | .doE items _ => do
          let body ← psPrintDoItems true smaller 4096 items
          return "do {\n  " ++ body.replace "\n" "\n  " ++ "\n}"
      | .byE tactics _ _ => do
          let body ← psPrintTactics smaller 4096 tactics
          return "by {\n  " ++ body.replace "\n" "\n  " ++ "\n}"
      | .sortE isType level _ => .ok (psPrintSyntaxSort isType level)
      | .reference name =>
          psPrintSyntaxName name
      | .scientific text _ =>
          Except.ok text
      | .natural text _ =>
          Except.ok text
      | .string text _ =>
          Except.ok text
      | .character text _ =>
          Except.ok text
      | .bool value _ =>
          if value then
            Except.ok "true"
          else
            Except.ok "false"
      | .unit _ =>
          Except.ok "()"
      | .record fields _ =>
          let printField :
              Prod PsSyntaxName PsSyntaxTerm ->
                Except PsSourcePrintError String :=
            fun (field : Prod PsSyntaxName PsSyntaxTerm) =>
              match psPrintSyntaxName field.fst with
              | Except.error error => Except.error error
              | Except.ok name =>
                  match smaller field.snd with
                  | Except.error error => Except.error error
                  | Except.ok value =>
                      Except.ok
                        (psPrintProofScriptConcat3 name " := " value);
          let printedFieldsResult :
              Except PsSourcePrintError (List String) :=
            psPrintProofScriptMapRecordFields printField fields;
          match printedFieldsResult with
          | Except.error error => Except.error error
          | Except.ok printedFields =>
              Except.ok
                (psPrintProofScriptConcat3 "{ " (psPrintJoin ", " printedFields) " }")
      | .recordUpdate source fields _ => do
          let source ← smaller source
          let fields ← fields.mapM fun (name, value) => do
            let name ← psPrintSyntaxName name
            let value ← smaller value
            pure (name ++ " := " ++ value)
          return "{ " ++ source ++ " with " ++ psPrintJoin ", " fields ++ " }"
      | .app fn args _ =>
          -- An empty argument list stays empty; Unit remains an explicit () argument.
          match smaller fn with
          | Except.error error => Except.error error
          | Except.ok printedFn =>
              let printArgument :
                  PsSyntaxTerm -> Except PsSourcePrintError String :=
                fun (argument : PsSyntaxTerm) =>
                  match smaller argument with
                  | Except.error error => Except.error error
                  | Except.ok printed =>
                      Except.ok (psPrintProofScriptGroupedTerm argument printed);
              let printedArgsResult :
                  Except PsSourcePrintError (List String) :=
                psPrintProofScriptMapTerms printArgument args;
              match printedArgsResult with
              | Except.error error => Except.error error
              | Except.ok printedArgs =>
                  Except.ok
                    (psPrintProofScriptConcat4
                      (psPrintProofScriptGroupedTerm fn printedFn)
                      "("
                      (psPrintJoin ", " printedArgs)
                      ")")
      | .lambda binders body _ =>
          let printBinder :
              Prod PsSyntaxBinderHead PsSyntaxTerm ->
                Except PsSourcePrintError String :=
            fun (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) => do
              let type ← smaller binder.snd
              psPrintTypedBinder binder.fst type;
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintProofScriptMapBinders printBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match
                  smaller body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    (psPrintProofScriptConcat4
                      "fun "
                      (psPrintJoin " " printedBinders)
                      " => "
                      printedBody)
      | .forallE binders body _ =>
          let printBinder :
              Prod PsSyntaxBinderHead PsSyntaxTerm ->
                Except PsSourcePrintError String :=
            fun (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) => do
              let type ← smaller binder.snd
              psPrintTypedBinder binder.fst type;
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintProofScriptMapBinders printBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match
                  smaller body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    (psPrintProofScriptConcat4 "forall " (psPrintJoin " " printedBinders) ", " printedBody)
      | .letE name type value body _ | .haveE name type value body _ =>
          match psPrintSyntaxName name with
          | Except.error error => Except.error error
          | Except.ok printedName =>
              let printType :
                  Except PsSourcePrintError String :=
                match type with
                | none => Except.ok ""
                | some declaredType =>
                    match
                        smaller declaredType with
                    | Except.error error => Except.error error
                    | Except.ok printed =>
                        Except.ok (psPrintProofScriptConcat2 " : " printed);
              match printType with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match
                      smaller value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      match
                          smaller body with
                      | Except.error error => Except.error error
                      | Except.ok printedBody =>
                          Except.ok
                            (psPrintProofScriptConcat6
                              (match term with | .haveE .. => "have " | _ => "let ")
                              printedName
                              printedType
                              " := "
                              (psPrintProofScriptGroupedTerm value printedValue)
                              (psPrintProofScriptConcat2 "\n" printedBody))
      | .ifE proofName condition thenBranch elseBranch _ =>
          match
              smaller condition with
          | Except.error error => Except.error error
          | Except.ok printedCondition =>
              match
                  smaller thenBranch with
              | Except.error error => Except.error error
              | Except.ok printedThen =>
                  match
                      smaller elseBranch with
                  | Except.error error => Except.error error
                  | Except.ok printedElse =>
                      Except.ok
                        (psPrintProofScriptConcat6
                          "if ("
                          ((match proofName with
                            | none => ""
                            | some name => String.intercalate "." name.segments ++ " : ") ++ printedCondition)
                          ") { "
                          printedThen
                          " } else { "
                          (psPrintProofScriptConcat2 printedElse " }"))
      | .matchMany discriminants alternatives generalizing? _ => do
          let plain := generalizing?.isNone &&
            discriminants.all (fun discriminant => discriminant.equationName?.isNone)
          let printed ← discriminants.mapM fun discriminant => do
            let term ← smaller discriminant.term
            match discriminant.equationName? with
            | none => return term
            | some name => return (← psPrintSyntaxName name) ++ " : " ++ term
          let discriminants := String.intercalate ", " printed
          let configuration := match generalizing? with
            | none => ""
            | some flag => "(generalizing := " ++ (if flag then "true" else "false") ++ ") "
          let alternatives ← alternatives.mapM fun (patterns, body, _) => do
            let patterns ← patterns.mapM psPrintPattern
            let body ← smaller body
            return "  | " ++ String.intercalate ", " patterns ++ " => " ++ body
          if alternatives.isEmpty && plain then return "nomatch " ++ discriminants
          return "match " ++ configuration ++ discriminants ++ " with {\n" ++ String.intercalate "\n" alternatives ++ "\n}"

def psPrintProofScriptTerm
    (term : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  psPrintProofScriptTermWithFuel 4096 term

def psPrintProofScriptBinder
    (binder : PsSyntaxBinderHead × PsSyntaxTerm) :
    Except PsSourcePrintError String := do
  let type ← psPrintProofScriptTerm binder.snd
  psPrintTypedBinder binder.fst type

-- Declaration and constructor headers share one explicit comma group.
-- Non-explicit binders remain in their original prefix; never reorder a
-- telescope to make an unsupported header printable.
def psPrintProofScriptExplicitEntry
    (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) :
    Except PsSourcePrintError String := do
  let head := Prod.fst binder
  if !head.moreNames.isEmpty then
    throw (.unsupportedSourceForm "native explicit group needs scope-preserving declaration lowering")
  match psPrintSyntaxName head.name with
  | Except.error error => Except.error error
  | Except.ok name =>
      match psPrintProofScriptTerm (Prod.snd binder) with
      | Except.error error => Except.error error
      | Except.ok printedType =>
          Except.ok (psPrintProofScriptConcat3 name " : " printedType)

def psPrintProofScriptExplicitEntries
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsSourcePrintError (List String) :=
  match binders with
  | List.nil => Except.ok List.nil
  | List.cons binder rest =>
      let head := Prod.fst binder;
      match head.kind with
      | PsSyntaxBinderKind.explicit =>
          match psPrintProofScriptExplicitEntry binder with
          | Except.error error => Except.error error
          | Except.ok printed =>
              match psPrintProofScriptExplicitEntries rest with
              | Except.error error => Except.error error
              | Except.ok tail => Except.ok (List.cons printed tail)
      | _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm
            "non-explicit binder after an explicit declaration parameter")

def psPrintProofScriptDeclarationBinders
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsSourcePrintError String :=
  match binders with
  | List.nil => Except.ok ""
  | List.cons binder rest =>
      let head := Prod.fst binder;
      match head.kind with
      | PsSyntaxBinderKind.explicit =>
          match psPrintProofScriptExplicitEntries binders with
          | Except.error error => Except.error error
          | Except.ok entries =>
              Except.ok (psPrintProofScriptConcat3 "(" (psPrintJoin ", " entries) ")")
      | _ =>
          match psPrintProofScriptBinder binder with
          | Except.error error => Except.error error
          | Except.ok printed =>
              match psPrintProofScriptDeclarationBinders rest with
              | Except.error error => Except.error error
              | Except.ok tail =>
                  Except.ok (psPrintProofScriptConcat3 " " printed tail)

def psPrintProofScriptStructureField
    (field : PsSyntaxBinderHead × PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match field with
  | Prod.mk head type =>
      match psPrintSyntaxName head.name with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psPrintProofScriptTerm type with
          | Except.error error => Except.error error
          | Except.ok printedType =>
              let value : String :=
                match head.kind with
                | .explicit => psPrintProofScriptConcat3 name " : " printedType
                | .implicit => psPrintProofScriptConcat5 "{" name " : " printedType "}"
                | .strictImplicit => psPrintProofScriptConcat5 "{{" name " : " printedType "}}"
                | .instanceImplicit => psPrintProofScriptConcat5 "[" name " : " printedType "]";
              Except.ok (psPrintProofScriptConcat2 "  " value)

def psPrintProofScriptSpaceJoinedSuffix
    (values : List String) : String :=
  match values with
  | List.nil => ""
  | List.cons _ _ =>
      psPrintProofScriptConcat2 " " (psPrintJoin " " values)

def psPrintProofScriptMapConstructors
    (printConstructor :
      PsSyntaxInductiveConstructor ->
        Except PsSourcePrintError String)
    (constructors : List PsSyntaxInductiveConstructor) :
    Except PsSourcePrintError (List String) :=
  match constructors with
  | List.nil =>
      Except.ok List.nil
  | List.cons constructor rest =>
      let printedHeadResult :=
        printConstructor constructor;
      match printedHeadResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedHead =>
          let printedTailResult :=
            psPrintProofScriptMapConstructors printConstructor rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintProofScriptMapImports
    (printImport :
      PsSyntaxImport -> Except PsSourcePrintError String)
    (imports : List PsSyntaxImport) :
    Except PsSourcePrintError (List String) :=
  match imports with
  | List.nil =>
      Except.ok List.nil
  | List.cons sourceImport rest =>
      let printedHeadResult :=
        printImport sourceImport;
      match printedHeadResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedHead =>
          let printedTailResult :=
            psPrintProofScriptMapImports printImport rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintProofScriptMapDeclarations
    (printDeclaration :
      PsSyntaxDeclaration -> Except PsSourcePrintError String)
    (declarations : List PsSyntaxDeclaration) :
    Except PsSourcePrintError (List String) :=
  match declarations with
  | List.nil =>
      Except.ok List.nil
  | List.cons declaration rest =>
      let printedHeadResult :=
        printDeclaration declaration;
      match printedHeadResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedHead =>
          let printedTailResult :=
            psPrintProofScriptMapDeclarations printDeclaration rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintProofScriptConstructor
    (constructor : PsSyntaxInductiveConstructor) :
    Except PsSourcePrintError String :=
  match psPrintSyntaxName constructor.name with
  | Except.error error => Except.error error
  | Except.ok name =>
      match psPrintProofScriptDeclarationBinders constructor.fields with
      | Except.error error => Except.error error
      | Except.ok suffix =>
          match constructor.resultType with
          | none => Except.ok (psPrintProofScriptConcat3 "  | " name suffix)
          | some type =>
            match psPrintProofScriptTerm type with
            | .error error => .error error
            | .ok type => .ok ("  | " ++ name ++ suffix ++ " : " ++ type)

def psPrintProofScriptTermination (termination : PsSyntaxTermination) :
    Except PsSourcePrintError String := do
  let measure ← psPrintProofScriptTerm termination.measure
  let proof ← match termination.decreasing with
    | none => pure ""
    | some (.byE tactics scope span) => do
      let body ← psPrintProofScriptTerm (.byE tactics scope span)
      pure ("\ndecreasing_by " ++ body)
    | some _ => throw (.unsupportedSourceForm "decreasing_by requires a proof sequence")
  return "\ntermination_by " ++ measure ++ proof

def psPrintProofScriptLocalDefinition (declaration : PsSyntaxLocalDefinition) :
    Except PsSourcePrintError String := do
  let name ← psPrintSyntaxName declaration.name
  let binders ← psPrintProofScriptDeclarationBinders declaration.binders
  let annotation ← match declaration.type with
    | none => pure ""
    | some type => do
      let printed ← psPrintProofScriptTerm type
      pure (" : " ++ printed)
  let value ← psPrintProofScriptTerm declaration.value
  let suffix ← match declaration.recursion with
    | none => pure ""
    | some (.fixedpoint _) => pure "\npartial_fixpoint"
    | some (.total termination) => psPrintProofScriptTermination termination
  return "def " ++ name ++ binders ++ annotation ++ " := " ++ value ++ suffix

def psPrintProofScriptDeclaration
    (declaration : PsSyntaxDeclaration) :
    Except PsSourcePrintError String :=
  match declaration with
  | .whereDeclaration parent locals _ => do
      let parent ← psPrintProofScriptDeclaration parent
      let locals ← locals.mapM psPrintProofScriptLocalDefinition
      if locals.isEmpty then throw (.unsupportedSourceForm "where requires local definitions")
      return parent ++ "\nwhere {\n  " ++ (String.intercalate "\n" locals).replace "\n" "\n  " ++ "\n}"
  | .definition name binders type value _
  | .noncomputableDefinition name binders type value _
  | .fixedpointDefinition name binders type value _
  | .wellFoundedDefinition name binders type value _ _ => do
      let suffix ← match declaration with
        | .fixedpointDefinition .. => pure "\npartial_fixpoint"
        | .wellFoundedDefinition _ _ _ _ termination _ => psPrintProofScriptTermination termination
        | _ => pure ""
      let printedName ← psPrintSyntaxName name
      let printedBinders ← psPrintProofScriptDeclarationBinders binders
      let annotation ← psPrintDeclarationResult psPrintProofScriptTerm type
      let printedValue ← psPrintProofScriptTerm value
      let declarationPrefix := match declaration with
        | .noncomputableDefinition .. => "noncomputable def "
        | _ => "def "
      return declarationPrefix ++ printedName ++ printedBinders ++
        annotation ++ " := " ++ printedValue ++ suffix
  | .partialDefinition name binders type value _ => do
      let printedName ← psPrintSyntaxName name
      let printedBinders ← psPrintProofScriptDeclarationBinders binders
      let annotation ← psPrintDeclarationResult psPrintProofScriptTerm type
      let printedValue ← psPrintProofScriptTerm value
      return "partial def " ++ printedName ++ printedBinders ++
        annotation ++ " := " ++ printedValue
  | .theoremDecl name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :
              Except PsSourcePrintError String :=
            psPrintProofScriptDeclarationBinders binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintProofScriptTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintProofScriptTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      Except.ok
                        (psPrintProofScriptConcat6
                          "theorem "
                          printedName
                          printedBinders
                          " : "
                          printedType
                          (psPrintProofScriptConcat2 " := " printedValue))
  | .inductiveDecl name params resultType constructors _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedParamsResult :
              Except PsSourcePrintError String :=
            psPrintProofScriptDeclarationBinders params;
          match printedParamsResult with
          | Except.error error => Except.error error
          | Except.ok printedParams =>
              let printResult :
                  Except PsSourcePrintError String :=
                match resultType with
                | none => Except.ok ""
                | some type =>
                    match psPrintProofScriptTerm type with
                    | Except.error error => Except.error error
                    | Except.ok printed =>
                        Except.ok (psPrintProofScriptConcat2 " : " printed);
              match printResult with
              | Except.error error => Except.error error
              | Except.ok printedResult =>
                  let printedConstructorsResult :
                      Except PsSourcePrintError (List String) :=
                    psPrintProofScriptMapConstructors
                      psPrintProofScriptConstructor
                      constructors;
                  match printedConstructorsResult with
                  | Except.error error => Except.error error
                  | Except.ok printedConstructors =>
                      Except.ok
                        (psPrintProofScriptConcat6
                          "inductive "
                          printedName
                          printedParams
                          printedResult
                          " where {\n"
                          (psPrintProofScriptConcat2
                            (psPrintJoin "\n" printedConstructors)
                            "\n}"))
  | .structureDecl name params result fields _ => do
      let name ← psPrintSyntaxName name
      let params ← psPrintProofScriptDeclarationBinders params
      let result ← match result with
        | none => pure ""
        | some type => do
          let type ← psPrintProofScriptTerm type
          pure (" : " ++ type)
      let fields ← psPrintProofScriptMapBinders psPrintProofScriptStructureField fields
      return "structure " ++ name ++ params ++ result ++
        " where {\n" ++ psPrintJoin "\n" fields ++ "\n}"

def psPrintProofScriptImport
    (sourceImport : PsSyntaxImport) :
    Except PsSourcePrintError String :=
  let printedNameResult :=
    psPrintSyntaxName sourceImport.moduleName;
  match printedNameResult with
  | Except.error error => Except.error error
  | Except.ok name =>
      Except.ok (psPrintProofScriptConcat2 "import " name)

def psPrintProofScriptAppendStrings
    (xs : List String) : List String -> List String :=
  match xs with
  | List.nil =>
      fun (ys : List String) => ys
  | List.cons head tail =>
      let smaller : List String -> List String :=
        psPrintProofScriptAppendStrings tail;
      fun (ys : List String) =>
        List.cons head (smaller ys)

def psPrintProofScriptModuleParts
    (sourceImports : List PsSyntaxImport)
    (sourceDeclarations : List PsSyntaxDeclaration) :
    Except PsSourcePrintError String :=
  let importsResult :
      Except PsSourcePrintError (List String) :=
    psPrintProofScriptMapImports
      psPrintProofScriptImport
      sourceImports;
  match importsResult with
  | Except.error error => Except.error error
  | Except.ok imports =>
      let declarationsResult :
          Except PsSourcePrintError (List String) :=
        psPrintProofScriptMapDeclarations
          psPrintProofScriptDeclaration
          sourceDeclarations;
      match declarationsResult with
      | Except.error error => Except.error error
      | Except.ok declarations =>
          let importSections : List String :=
            match imports with
            | List.nil =>
                List.nil
            | List.cons _ _ =>
                List.cons (psPrintJoin "\n" imports) List.nil;
          let declarationSections : List String :=
            match declarations with
            | List.nil =>
                List.nil
            | List.cons _ _ =>
                List.cons
                  (psPrintJoin "\n\n" declarations)
                  List.nil;
          let sections : List String :=
            psPrintProofScriptAppendStrings
              importSections
              declarationSections;
          match sections with
          | List.nil =>
              Except.ok ""
          | List.cons _ _ =>
              Except.ok
                (psPrintProofScriptConcat2
                  (psPrintJoin "\n\n" sections)
                  "\n")

def psPrintProofScriptModule
    (module : PsSyntaxModule) :
    Except PsSourcePrintError String :=
  match module with
  | PsSyntaxModule.mk sourceImports sourceDeclarations =>
      psPrintProofScriptModuleParts sourceImports sourceDeclarations

