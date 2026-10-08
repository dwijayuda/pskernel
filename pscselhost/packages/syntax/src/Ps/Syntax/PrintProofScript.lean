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

def psPrintProofScriptUnitCallArgs
    (args : List PsSyntaxTerm) : Bool :=
  match args with
  | List.nil => false
  | List.cons argument rest =>
      match argument with
      | .unit _ =>
          match rest with
          | List.nil => true
          | List.cons _ _ => false
      | _ => false

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
      let smaller :
          PsSyntaxTerm -> Except PsSourcePrintError String :=
        psPrintProofScriptTermWithFuel remaining;
      fun (term : PsSyntaxTerm) =>
      match term with
      | .reference name =>
          psPrintSyntaxName name
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
      | .app fn args _ =>
          if psPrintProofScriptBoolNot (psSyntaxTermSimpleForApplication fn) then
            Except.error PsSourcePrintError.unsupportedApplication
          else
            match smaller fn with
            | Except.error error => Except.error error
            | Except.ok printedFn =>
                if psPrintProofScriptUnitCallArgs args then
                  Except.ok (psPrintProofScriptConcat2 printedFn "()")
                else
                  let printedArgsResult :
                      Except PsSourcePrintError (List String) :=
                    psPrintProofScriptMapTerms smaller args;
                  match printedArgsResult with
                  | Except.error error => Except.error error
                  | Except.ok printedArgs =>
                      Except.ok
                        (psPrintProofScriptConcat4
                          printedFn
                          "("
                          (psPrintJoin ", " printedArgs)
                          ")")
      | .lambda binders body _ =>
          let printBinder :
              Prod PsSyntaxBinderHead PsSyntaxTerm ->
                Except PsSourcePrintError String :=
            fun (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) =>
              match binder with
              | Prod.mk head type =>
                  match psPrintSyntaxName head.name with
                  | Except.error error => Except.error error
                  | Except.ok name =>
                      match
                          smaller type with
                      | Except.error error => Except.error error
                      | Except.ok printedType =>
                          let delimiters :=
                            psPrintBinderDelimiters head.kind;
                          Except.ok
                            (psPrintProofScriptConcat5
                              delimiters.fst
                              name
                              " : "
                              printedType
                              delimiters.snd);
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
            fun (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) =>
              match binder with
              | Prod.mk head type =>
                  match psPrintSyntaxName head.name with
                  | Except.error error => Except.error error
                  | Except.ok name =>
                      match
                          smaller type with
                      | Except.error error => Except.error error
                      | Except.ok printedType =>
                          let delimiters :=
                            psPrintBinderDelimiters head.kind;
                          Except.ok
                            (psPrintProofScriptConcat5
                              delimiters.fst
                              name
                              " : "
                              printedType
                              delimiters.snd);
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
                    (psPrintArrowChain printedBinders printedBody)
      | .letE name type value body _ =>
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
                              "let "
                              printedName
                              printedType
                              " := "
                              printedValue
                              (psPrintProofScriptConcat2 "; " printedBody))
      | .ifE condition thenBranch elseBranch _ =>
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
                          printedCondition
                          ") { "
                          printedThen
                          " } else { "
                          (psPrintProofScriptConcat2 printedElse " }"))
      | .matchE scrutinee alternatives _ =>
          match
              smaller scrutinee with
          | Except.error error => Except.error error
          | Except.ok printedScrutinee =>
              let printAlternative :
                  Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan) ->
                    Except PsSourcePrintError String :=
                fun (alternative : Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)) =>
                  match alternative with
                  | Prod.mk pattern bodyAndSpan =>
                      match bodyAndSpan with
                      | Prod.mk body _ =>
                          match psPrintPattern pattern with
                          | Except.error error => Except.error error
                          | Except.ok printedPattern =>
                              match
                                  smaller body with
                              | Except.error error => Except.error error
                              | Except.ok printedBody =>
                                  Except.ok
                                    (psPrintProofScriptConcat5
                                      "  | "
                                      printedPattern
                                      " => "
                                      printedBody
                                      ";");
              let printedAlternativesResult :
                  Except PsSourcePrintError (List String) :=
                psPrintProofScriptMapAlternatives
                  printAlternative
                  alternatives;
              match printedAlternativesResult with
              | Except.error error => Except.error error
              | Except.ok printedAlternatives =>
                  Except.ok
                    (psPrintProofScriptConcat5
                      "match "
                      printedScrutinee
                      " with {\n"
                      (psPrintJoin "\n" printedAlternatives)
                      "\n}")

def psPrintProofScriptTerm
    (term : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  psPrintProofScriptTermWithFuel 4096 term

def psPrintProofScriptBinder
    (binder : PsSyntaxBinderHead × PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match binder with
  | Prod.mk head type =>
      match psPrintSyntaxName head.name with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psPrintProofScriptTerm type with
          | Except.error error => Except.error error
          | Except.ok printedType =>
              let delimiters := psPrintBinderDelimiters head.kind;
              Except.ok
                (psPrintProofScriptConcat5
                  delimiters.fst
                  name
                  " : "
                  printedType
                  delimiters.snd)

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
              Except.ok (psPrintProofScriptConcat3 "  " value ";")

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
      let fieldsResult :
          Except PsSourcePrintError (List String) :=
        psPrintProofScriptMapBinders
          psPrintProofScriptBinder
          constructor.fields;
      match fieldsResult with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let suffix : String :=
            match fields with
            | List.nil => ""
            | List.cons _ _ =>
                psPrintProofScriptConcat2 " " (psPrintJoin " " fields);
          Except.ok (psPrintProofScriptConcat4 "  | " name suffix ";")

def psPrintProofScriptDeclaration
    (declaration : PsSyntaxDeclaration) :
    Except PsSourcePrintError String :=
  match declaration with
  | .definition name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintProofScriptMapBinders psPrintProofScriptBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintProofScriptTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintProofScriptTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        psPrintProofScriptSpaceJoinedSuffix printedBinders;
                      Except.ok
                        (psPrintProofScriptConcat6
                          "def "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintProofScriptConcat3 " := " printedValue ";"))
  | .partialDefinition name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintProofScriptMapBinders psPrintProofScriptBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintProofScriptTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintProofScriptTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        psPrintProofScriptSpaceJoinedSuffix printedBinders;
                      Except.ok
                        (psPrintProofScriptConcat6
                          "partial def "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintProofScriptConcat3 " := " printedValue ";"))
  | .theoremDecl name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintProofScriptMapBinders psPrintProofScriptBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintProofScriptTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintProofScriptTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        psPrintProofScriptSpaceJoinedSuffix printedBinders;
                      Except.ok
                        (psPrintProofScriptConcat6
                          "theorem "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintProofScriptConcat3 " := " printedValue ";"))
  | .inductiveDecl name params resultType constructors _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedParamsResult :
              Except PsSourcePrintError (List String) :=
            psPrintProofScriptMapBinders psPrintProofScriptBinder params;
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
                      let paramSuffix :=
                        psPrintProofScriptSpaceJoinedSuffix printedParams;
                      Except.ok
                        (psPrintProofScriptConcat6
                          "inductive "
                          printedName
                          paramSuffix
                          printedResult
                          " where {\n"
                          (psPrintProofScriptConcat2
                            (psPrintJoin "\n" printedConstructors)
                            "\n};"))
  | .structureDecl name params fields _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedParamsResult :
              Except PsSourcePrintError (List String) :=
            psPrintProofScriptMapBinders psPrintProofScriptBinder params;
          match printedParamsResult with
          | Except.error error => Except.error error
          | Except.ok printedParams =>
              let printedFieldsResult :
                  Except PsSourcePrintError (List String) :=
                psPrintProofScriptMapBinders
                  psPrintProofScriptStructureField
                  fields;
              match printedFieldsResult with
              | Except.error error => Except.error error
              | Except.ok printedFields =>
                  let paramSuffix :=
                    psPrintProofScriptSpaceJoinedSuffix printedParams;
                  Except.ok
                    (psPrintProofScriptConcat6
                      "structure "
                      printedName
                      paramSuffix
                      " where {\n"
                      (psPrintJoin "\n" printedFields)
                      "\n};")

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
