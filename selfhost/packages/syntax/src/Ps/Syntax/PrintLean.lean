import Ps.Syntax.PrintCommon

def psPrintLeanTermWithFuel :
    Nat -> PsSyntaxTerm -> Except PsSourcePrintError String
  | 0, _ => Except.error PsSourcePrintError.fuelExhausted
  | remaining + 1, term =>
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
          Except.ok (if value then "true" else "false")
      | .unit _ =>
          Except.ok "()"
      | .app fn args _ =>
          if !psSyntaxTermSimpleForApplication fn then
            Except.error PsSourcePrintError.unsupportedApplication
          else
            match psPrintLeanTermWithFuel remaining fn with
            | Except.error error => Except.error error
            | Except.ok printedFn =>
                match args.mapM (fun arg =>
                    if psSyntaxTermSimpleForApplication arg then
                      psPrintLeanTermWithFuel remaining arg
                    else
                      Except.error PsSourcePrintError.unsupportedApplication) with
                | Except.error error => Except.error error
                | Except.ok printedArgs =>
                    if printedArgs.isEmpty then
                      Except.ok printedFn
                    else
                      Except.ok
                        (printedFn ++ " " ++ psPrintJoin " " printedArgs)
      | .lambda binders body _ =>
          let printBinder :=
            fun binder =>
              match binder with
              | (head, type) =>
                  match psPrintSyntaxName head.name with
                  | Except.error error => Except.error error
                  | Except.ok name =>
                      match psPrintLeanTermWithFuel remaining type with
                      | Except.error error => Except.error error
                      | Except.ok printedType =>
                          let delimiters :=
                            psPrintBinderDelimiters head.kind
                          Except.ok
                            (delimiters.1 ++ name ++ " : " ++
                              printedType ++ delimiters.2)
          match binders.mapM printBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintLeanTermWithFuel remaining body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    ("fun " ++ psPrintJoin " " printedBinders ++
                      " => " ++ printedBody)
      | .forallE binders body _ =>
          let printBinder :=
            fun binder =>
              match binder with
              | (head, type) =>
                  match psPrintSyntaxName head.name with
                  | Except.error error => Except.error error
                  | Except.ok name =>
                      match psPrintLeanTermWithFuel remaining type with
                      | Except.error error => Except.error error
                      | Except.ok printedType =>
                          let delimiters :=
                            psPrintBinderDelimiters head.kind
                          Except.ok
                            (delimiters.1 ++ name ++ " : " ++
                              printedType ++ delimiters.2)
          match binders.mapM printBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintLeanTermWithFuel remaining body with
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
                        psPrintLeanTermWithFuel
                          remaining
                          declaredType with
                    | Except.error error => Except.error error
                    | Except.ok printed =>
                        Except.ok (" : " ++ printed)
              match printType with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintLeanTermWithFuel remaining value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      match psPrintLeanTermWithFuel remaining body with
                      | Except.error error => Except.error error
                      | Except.ok printedBody =>
                          Except.ok
                            ("let " ++ printedName ++ printedType ++
                              " := " ++ printedValue ++
                              "; " ++ printedBody)
      | .ifE condition thenBranch elseBranch _ =>
          match psPrintLeanTermWithFuel remaining condition with
          | Except.error error => Except.error error
          | Except.ok printedCondition =>
              match psPrintLeanTermWithFuel remaining thenBranch with
              | Except.error error => Except.error error
              | Except.ok printedThen =>
                  match psPrintLeanTermWithFuel remaining elseBranch with
                  | Except.error error => Except.error error
                  | Except.ok printedElse =>
                      Except.ok
                        ("if " ++ printedCondition ++
                          " then " ++ printedThen ++
                          " else " ++ printedElse)
      | .matchE scrutinee alternatives _ =>
          match psPrintLeanTermWithFuel remaining scrutinee with
          | Except.error error => Except.error error
          | Except.ok printedScrutinee =>
              let printAlternative :=
                fun alternative =>
                  match alternative with
                  | (pattern, body, _) =>
                      match psPrintPattern pattern with
                      | Except.error error => Except.error error
                      | Except.ok printedPattern =>
                          match
                              psPrintLeanTermWithFuel remaining body with
                          | Except.error error => Except.error error
                          | Except.ok printedBody =>
                              Except.ok
                                ("  | " ++ printedPattern ++
                                  " => " ++ printedBody)
              match alternatives.mapM printAlternative with
              | Except.error error => Except.error error
              | Except.ok printedAlternatives =>
                  Except.ok
                    ("match " ++ printedScrutinee ++ " with\n" ++
                      psPrintJoin "\n" printedAlternatives)

def psPrintLeanTerm
    (term : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  psPrintLeanTermWithFuel 4096 term

def psPrintLeanBinder
    (binder : PsSyntaxBinderHead × PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match binder with
  | (head, type) =>
      match psPrintSyntaxName head.name with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psPrintLeanTerm type with
          | Except.error error => Except.error error
          | Except.ok printedType =>
              let delimiters := psPrintBinderDelimiters head.kind
              Except.ok
                (delimiters.1 ++ name ++ " : " ++
                  printedType ++ delimiters.2)

def psPrintLeanStructureField
    (field : PsSyntaxBinderHead × PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match field with
  | (head, type) =>
      match psPrintSyntaxName head.name with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psPrintLeanTerm type with
          | Except.error error => Except.error error
          | Except.ok printedType =>
              let value :=
                match head.kind with
                | .explicit => name ++ " : " ++ printedType
                | .implicit => "{" ++ name ++ " : " ++ printedType ++ "}"
                | .strictImplicit => "{{" ++ name ++ " : " ++ printedType ++ "}}"
                | .instanceImplicit => "[" ++ name ++ " : " ++ printedType ++ "]"
              Except.ok ("  " ++ value)

def psPrintLeanConstructor
    (constructor : PsSyntaxInductiveConstructor) :
    Except PsSourcePrintError String :=
  match psPrintSyntaxName constructor.name with
  | Except.error error => Except.error error
  | Except.ok name =>
      match constructor.fields.mapM psPrintLeanBinder with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let suffix :=
            if fields.isEmpty then ""
            else " " ++ psPrintJoin " " fields
          Except.ok ("  | " ++ name ++ suffix)

def psPrintLeanDeclaration
    (declaration : PsSyntaxDeclaration) :
    Except PsSourcePrintError String :=
  match declaration with
  | .definition name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          match binders.mapM psPrintLeanBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintLeanTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintLeanTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        if printedBinders.isEmpty then ""
                        else " " ++ psPrintJoin " " printedBinders
                      Except.ok
                        ("def " ++ printedName ++ binderSuffix ++
                          " : " ++ printedType ++
                          " := " ++ printedValue)
  | .theoremDecl name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          match binders.mapM psPrintLeanBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintLeanTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintLeanTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        if printedBinders.isEmpty then ""
                        else " " ++ psPrintJoin " " printedBinders
                      Except.ok
                        ("theorem " ++ printedName ++ binderSuffix ++
                          " : " ++ printedType ++
                          " := " ++ printedValue)
  | .inductiveDecl name params resultType constructors _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          match params.mapM psPrintLeanBinder with
          | Except.error error => Except.error error
          | Except.ok printedParams =>
              let printResult :=
                match resultType with
                | none => Except.ok ""
                | some type =>
                    match psPrintLeanTerm type with
                    | Except.error error => Except.error error
                    | Except.ok printed =>
                        Except.ok (" : " ++ printed)
              match printResult with
              | Except.error error => Except.error error
              | Except.ok printedResult =>
                  match constructors.mapM psPrintLeanConstructor with
                  | Except.error error => Except.error error
                  | Except.ok printedConstructors =>
                      let paramSuffix :=
                        if printedParams.isEmpty then ""
                        else " " ++ psPrintJoin " " printedParams
                      Except.ok
                        ("inductive " ++ printedName ++
                          paramSuffix ++ printedResult ++
                          " where\n" ++
                          psPrintJoin "\n" printedConstructors)
  | .structureDecl name params fields _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          match params.mapM psPrintLeanBinder with
          | Except.error error => Except.error error
          | Except.ok printedParams =>
              match fields.mapM psPrintLeanStructureField with
              | Except.error error => Except.error error
              | Except.ok printedFields =>
                  let paramSuffix :=
                    if printedParams.isEmpty then ""
                    else " " ++ psPrintJoin " " printedParams
                  Except.ok
                    ("structure " ++ printedName ++ paramSuffix ++
                      " where\n" ++ psPrintJoin "\n" printedFields)

def psPrintLeanModule
    (module : PsSyntaxModule) :
    Except PsSourcePrintError String :=
  match module.imports.mapM
      (fun sourceImport =>
        match psPrintSyntaxName sourceImport.moduleName with
        | Except.error error => Except.error error
        | Except.ok name => Except.ok ("import " ++ name)) with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match module.declarations.mapM psPrintLeanDeclaration with
      | Except.error error => Except.error error
      | Except.ok declarations =>
          let sections :=
            (if imports.isEmpty then [] else [psPrintJoin "\n" imports]) ++
            (if declarations.isEmpty then []
             else [psPrintJoin "\n\n" declarations])
          if sections.isEmpty then
            Except.ok ""
          else
            Except.ok (psPrintJoin "\n\n" sections ++ "\n")
