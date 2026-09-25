import Ps.Syntax.PrintCommon

def psPrintProofScriptBoolNot (value : Bool) : Bool :=
  if value then false else true

def psPrintProofScriptTermWithFuel :
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
      | .record fields _ =>
          let printField :=
            fun (field : Prod PsSyntaxName PsSyntaxTerm) =>
              match psPrintSyntaxName field.fst with
              | Except.error error => Except.error error
              | Except.ok name =>
                  match psPrintProofScriptTermWithFuel remaining field.snd with
                  | Except.error error => Except.error error
                  | Except.ok value =>
                      Except.ok
                        (name ++ " := " ++ value)
          match fields.mapM printField with
          | Except.error error => Except.error error
          | Except.ok printedFields =>
              Except.ok
                ("{ " ++ psPrintJoin ", " printedFields ++ " }")
      | .app fn args _ =>
          if psPrintProofScriptBoolNot (psSyntaxTermSimpleForApplication fn) then
            Except.error PsSourcePrintError.unsupportedApplication
          else
            match psPrintProofScriptTermWithFuel remaining fn with
            | Except.error error => Except.error error
            | Except.ok printedFn =>
                match args with
                | [.unit _] =>
                    Except.ok (printedFn ++ "()")
                | _ =>
                    match args.mapM
                        (psPrintProofScriptTermWithFuel remaining) with
                    | Except.error error => Except.error error
                    | Except.ok printedArgs =>
                        Except.ok
                          (printedFn ++ "(" ++
                            psPrintJoin ", " printedArgs ++ ")")
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
                            psPrintBinderDelimiters head.kind
                          Except.ok
                            (delimiters.fst ++ name ++ " : " ++
                              printedType ++ delimiters.snd)
          match binders.mapM printBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match
                  psPrintProofScriptTermWithFuel remaining body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    ("fun " ++ psPrintJoin " " printedBinders ++
                      " => " ++ printedBody)
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
                            psPrintBinderDelimiters head.kind
                          Except.ok
                            (delimiters.fst ++ name ++ " : " ++
                              printedType ++ delimiters.snd)
          match binders.mapM printBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match
                  psPrintProofScriptTermWithFuel remaining body with
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
                        Except.ok (" : " ++ printed)
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
                            ("let " ++ printedName ++ printedType ++
                              " := " ++ printedValue ++
                              "; " ++ printedBody)
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
                        ("if (" ++ printedCondition ++
                          ") { " ++ printedThen ++
                          " } else { " ++ printedElse ++ " }")
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
                                    ("  | " ++ printedPattern ++
                                      " => " ++ printedBody ++ ";")
              match alternatives.mapM printAlternative with
              | Except.error error => Except.error error
              | Except.ok printedAlternatives =>
                  Except.ok
                    ("match " ++ printedScrutinee ++ " with {\n" ++
                      psPrintJoin "\n" printedAlternatives ++
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
              let delimiters := psPrintBinderDelimiters head.kind
              Except.ok
                (delimiters.fst ++ name ++ " : " ++
                  printedType ++ delimiters.snd)

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
              let value :=
                match head.kind with
                | .explicit => name ++ " : " ++ printedType
                | .implicit => "{" ++ name ++ " : " ++ printedType ++ "}"
                | .strictImplicit => "{{" ++ name ++ " : " ++ printedType ++ "}}"
                | .instanceImplicit => "[" ++ name ++ " : " ++ printedType ++ "]"
              Except.ok ("  " ++ value ++ ";")

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
            else " " ++ psPrintJoin " " fields
          Except.ok ("  | " ++ name ++ suffix ++ ";")

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
                        else " " ++ psPrintJoin " " printedBinders
                      Except.ok
                        ("def " ++ printedName ++ binderSuffix ++
                          " : " ++ printedType ++
                          " := " ++ printedValue ++ ";")
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
                        else " " ++ psPrintJoin " " printedBinders
                      Except.ok
                        ("partial def " ++ printedName ++ binderSuffix ++
                          " : " ++ printedType ++
                          " := " ++ printedValue ++ ";")
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
                        else " " ++ psPrintJoin " " printedBinders
                      Except.ok
                        ("theorem " ++ printedName ++ binderSuffix ++
                          " : " ++ printedType ++
                          " := " ++ printedValue ++ ";")
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
                        Except.ok (" : " ++ printed)
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
                        else " " ++ psPrintJoin " " printedParams
                      Except.ok
                        ("inductive " ++ printedName ++
                          paramSuffix ++ printedResult ++
                          " where {\n" ++
                          psPrintJoin "\n" printedConstructors ++
                          "\n};")
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
                    else " " ++ psPrintJoin " " printedParams
                  Except.ok
                    ("structure " ++ printedName ++ paramSuffix ++
                      " where {\n" ++ psPrintJoin "\n" printedFields ++
                      "\n};")

def psPrintProofScriptModule
    (module : PsSyntaxModule) :
    Except PsSourcePrintError String :=
  match module.imports.mapM
      (fun (sourceImport : PsSyntaxImport) =>
        match psPrintSyntaxName sourceImport.moduleName with
        | Except.error error => Except.error error
        | Except.ok name => Except.ok ("import " ++ name)) with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match
          module.declarations.mapM
            psPrintProofScriptDeclaration with
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
