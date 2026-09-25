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
          let printBinder :=
            fun (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) =>
              match binder with
              | Prod.mk head type =>
                  match psPrintSyntaxName head.name with
                  | Except.error error => Except.error error
                  | Except.ok name =>
                      match
                          psPrintProofScriptTermWithFuel
                            remaining
                            type with
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
          match binders.mapM printBinder with
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
          let printBinder :=
            fun (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) =>
              match binder with
              | Prod.mk head type =>
                  match psPrintSyntaxName head.name with
                  | Except.error error => Except.error error
                  | Except.ok name =>
                      match
                          psPrintProofScriptTermWithFuel
                            remaining
                            type with
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
          match binders.mapM printBinder with
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
              let printType :=
                match type with
                | none => Except.ok ""
                | some declaredType =>
                    match
                        psPrintProofScriptTermWithFuel
                          remaining
                          declaredType with
                    | Except.error error => Except.error error
                    | Except.ok printed =>
                        Except.ok (psPrintProofScriptConcat2 " : " printed);
              match printType with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match
                      psPrintProofScriptTermWithFuel
                        remaining
                        value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      match
                          psPrintProofScriptTermWithFuel
                            remaining
                            body with
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
              psPrintProofScriptTermWithFuel
                remaining
                condition with
          | Except.error error => Except.error error
          | Except.ok printedCondition =>
              match
                  psPrintProofScriptTermWithFuel
                    remaining
                    thenBranch with
              | Except.error error => Except.error error
              | Except.ok printedThen =>
                  match
                      psPrintProofScriptTermWithFuel
                        remaining
                        elseBranch with
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
              psPrintProofScriptTermWithFuel
                remaining
                scrutinee with
          | Except.error error => Except.error error
          | Except.ok printedScrutinee =>
              let printAlternative :=
                fun (alternative : Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)) =>
                  match alternative with
                  | Prod.mk pattern bodyAndSpan =>
                      match bodyAndSpan with
                      | Prod.mk body _ =>
                          match psPrintPattern pattern with
                          | Except.error error => Except.error error
                          | Except.ok printedPattern =>
                              match
                                  psPrintProofScriptTermWithFuel
                                    remaining
                                    body with
                              | Except.error error => Except.error error
                              | Except.ok printedBody =>
                                  Except.ok
                                    (psPrintProofScriptConcat5
                                      "  | "
                                      printedPattern
                                      " => "
                                      printedBody
                                      ";");
              match alternatives.mapM printAlternative with
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

def psPrintProofScriptConstructor
    (constructor : PsSyntaxInductiveConstructor) :
    Except PsSourcePrintError String :=
  match psPrintSyntaxName constructor.name with
  | Except.error error => Except.error error
  | Except.ok name =>
      match constructor.fields.mapM psPrintProofScriptBinder with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let suffix :=
            if fields.isEmpty then ""
            else psPrintProofScriptConcat2 " " (psPrintJoin " " fields);
          Except.ok (psPrintProofScriptConcat4 "  | " name suffix ";")

def psPrintProofScriptDeclaration
    (declaration : PsSyntaxDeclaration) :
    Except PsSourcePrintError String :=
  match declaration with
  | .definition name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          match binders.mapM psPrintProofScriptBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintProofScriptTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintProofScriptTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        if printedBinders.isEmpty then ""
                        else psPrintProofScriptConcat2 " " (psPrintJoin " " printedBinders);
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
          match binders.mapM psPrintProofScriptBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintProofScriptTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintProofScriptTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        if printedBinders.isEmpty then ""
                        else psPrintProofScriptConcat2 " " (psPrintJoin " " printedBinders);
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
          match binders.mapM psPrintProofScriptBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintProofScriptTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintProofScriptTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        if printedBinders.isEmpty then ""
                        else psPrintProofScriptConcat2 " " (psPrintJoin " " printedBinders);
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
          match params.mapM psPrintProofScriptBinder with
          | Except.error error => Except.error error
          | Except.ok printedParams =>
              let printResult :=
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
                  match
                      constructors.mapM
                        psPrintProofScriptConstructor with
                  | Except.error error => Except.error error
                  | Except.ok printedConstructors =>
                      let paramSuffix :=
                        if printedParams.isEmpty then ""
                        else psPrintProofScriptConcat2 " " (psPrintJoin " " printedParams);
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
          match params.mapM psPrintProofScriptBinder with
          | Except.error error => Except.error error
          | Except.ok printedParams =>
              match fields.mapM psPrintProofScriptStructureField with
              | Except.error error => Except.error error
              | Except.ok printedFields =>
                  let paramSuffix :=
                    if printedParams.isEmpty then ""
                    else psPrintProofScriptConcat2 " " (psPrintJoin " " printedParams);
                  Except.ok
                    (psPrintProofScriptConcat6
                      "structure "
                      printedName
                      paramSuffix
                      " where {\n"
                      (psPrintJoin "\n" printedFields)
                      "\n};")

def psPrintProofScriptModule
    (module : PsSyntaxModule) :
    Except PsSourcePrintError String :=
  let printImport :=
    fun (sourceImport : PsSyntaxImport) =>
      match psPrintSyntaxName sourceImport.moduleName with
      | Except.error error => Except.error error
      | Except.ok name =>
          Except.ok (psPrintProofScriptConcat2 "import " name);
  match module.imports.mapM printImport with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match
          module.declarations.mapM
            psPrintProofScriptDeclaration with
      | Except.error error => Except.error error
      | Except.ok declarations =>
          let importSections :=
            if imports.isEmpty then
              List.nil
            else
              List.cons (psPrintJoin "\n" imports) List.nil;
          let declarationSections :=
            if declarations.isEmpty then
              List.nil
            else
              List.cons (psPrintJoin "\n\n" declarations) List.nil;
          let sections :=
            List.append importSections declarationSections;
          if sections.isEmpty then
            Except.ok ""
          else
            Except.ok
              (psPrintProofScriptConcat2
                (psPrintJoin "\n\n" sections)
                "\n")
