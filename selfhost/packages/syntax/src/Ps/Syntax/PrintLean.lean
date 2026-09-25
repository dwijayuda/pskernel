import Ps.Syntax.PrintCommon

def psPrintLeanBoolNot (value : Bool) : Bool :=
  if value then false else true

def psPrintLeanConcat2
    (a b : String) : String :=
  String.Internal.append a b

def psPrintLeanConcat3
    (a b c : String) : String :=
  let ab := psPrintLeanConcat2 a b;
  psPrintLeanConcat2 ab c

def psPrintLeanConcat4
    (a b c d : String) : String :=
  let abc := psPrintLeanConcat3 a b c;
  psPrintLeanConcat2 abc d

def psPrintLeanConcat5
    (a b c d e : String) : String :=
  let abcd := psPrintLeanConcat4 a b c d;
  psPrintLeanConcat2 abcd e

def psPrintLeanConcat6
    (a b c d e f : String) : String :=
  let abcde := psPrintLeanConcat5 a b c d e;
  psPrintLeanConcat2 abcde f

def psPrintLeanTermWithFuel :
    Nat -> PsSyntaxTerm -> Except PsSourcePrintError String
  | 0 =>
      fun (_term : PsSyntaxTerm) =>
        Except.error PsSourcePrintError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsSyntaxTerm -> Except PsSourcePrintError String :=
        smaller;
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
                        (psPrintLeanConcat3 name " := " value);
          match fields.mapM printField with
          | Except.error error => Except.error error
          | Except.ok printedFields =>
              Except.ok
                (psPrintLeanConcat3 "{ " (psPrintJoin ", " printedFields) " }")
      | .app fn args _ =>
          if psPrintLeanBoolNot (psSyntaxTermSimpleForApplication fn) then
            Except.error PsSourcePrintError.unsupportedApplication
          else
            match smaller fn with
            | Except.error error => Except.error error
            | Except.ok printedFn =>
                let printArgument :=
                  fun (arg : PsSyntaxTerm) =>
                    match smaller arg with
                    | Except.error error => Except.error error
                    | Except.ok printed =>
                        if psSyntaxTermSimpleForApplication arg then
                          Except.ok printed
                        else
                          Except.ok (psPrintLeanConcat3 "(" printed ")");
                match args.mapM printArgument with
                | Except.error error => Except.error error
                | Except.ok printedArgs =>
                    if printedArgs.isEmpty then
                      Except.ok printedFn
                    else
                      Except.ok
                        (psPrintLeanConcat3 printedFn " " (psPrintJoin " " printedArgs))
      | .lambda binders body _ =>
          let printBinder :=
            fun (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) =>
              match binder with
              | Prod.mk head type =>
                  match psPrintSyntaxName head.name with
                  | Except.error error => Except.error error
                  | Except.ok name =>
                      match smaller type with
                      | Except.error error => Except.error error
                      | Except.ok printedType =>
                          let delimiters :=
                            psPrintBinderDelimiters head.kind;
                          Except.ok
                            (psPrintLeanConcat5
                              delimiters.fst
                              name
                              " : "
                              printedType
                              delimiters.snd);
          match binders.mapM printBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match smaller body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    (psPrintLeanConcat4
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
                      match smaller type with
                      | Except.error error => Except.error error
                      | Except.ok printedType =>
                          let delimiters :=
                            psPrintBinderDelimiters head.kind;
                          Except.ok
                            (psPrintLeanConcat5
                              delimiters.fst
                              name
                              " : "
                              printedType
                              delimiters.snd);
          match binders.mapM printBinder with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match smaller body with
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
                        Except.ok (psPrintLeanConcat2 " : " printed);
              match printType with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match smaller value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      match smaller body with
                      | Except.error error => Except.error error
                      | Except.ok printedBody =>
                          Except.ok
                            (psPrintLeanConcat6
                              "let "
                              printedName
                              printedType
                              " := "
                              printedValue
                              (psPrintLeanConcat2 "; " printedBody))
      | .ifE condition thenBranch elseBranch _ =>
          match smaller condition with
          | Except.error error => Except.error error
          | Except.ok printedCondition =>
              match smaller thenBranch with
              | Except.error error => Except.error error
              | Except.ok printedThen =>
                  match smaller elseBranch with
                  | Except.error error => Except.error error
                  | Except.ok printedElse =>
                      Except.ok
                        (psPrintLeanConcat6
                          "if "
                          printedCondition
                          " then "
                          printedThen
                          " else "
                          printedElse)
      | .matchE scrutinee alternatives _ =>
          match smaller scrutinee with
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
                                  smaller body with
                              | Except.error error => Except.error error
                              | Except.ok printedBody =>
                                  Except.ok
                                    (psPrintLeanConcat4
                                      "  | "
                                      printedPattern
                                      " => "
                                      printedBody);
              match alternatives.mapM printAlternative with
              | Except.error error => Except.error error
              | Except.ok printedAlternatives =>
                  Except.ok
                    (psPrintLeanConcat4
                      "match "
                      printedScrutinee
                      " with\n"
                      (psPrintJoin "\n" printedAlternatives))

def psPrintLeanTerm
    (term : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  psPrintLeanTermWithFuel 4096 term

def psPrintLeanBinder
    (binder : PsSyntaxBinderHead × PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match binder with
  | Prod.mk head type =>
      match psPrintSyntaxName head.name with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psPrintLeanTerm type with
          | Except.error error => Except.error error
          | Except.ok printedType =>
              let delimiters := psPrintBinderDelimiters head.kind;
              Except.ok
                (psPrintLeanConcat5
                  delimiters.fst
                  name
                  " : "
                  printedType
                  delimiters.snd)

def psPrintLeanStructureField
    (field : PsSyntaxBinderHead × PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match field with
  | Prod.mk head type =>
      match psPrintSyntaxName head.name with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psPrintLeanTerm type with
          | Except.error error => Except.error error
          | Except.ok printedType =>
              let value :=
                match head.kind with
                | .explicit => psPrintLeanConcat3 name " : " printedType
                | .implicit => psPrintLeanConcat5 "{" name " : " printedType "}"
                | .strictImplicit => psPrintLeanConcat5 "{{" name " : " printedType "}}"
                | .instanceImplicit => psPrintLeanConcat5 "[" name " : " printedType "]";
              Except.ok (psPrintLeanConcat2 "  " value)

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
            else psPrintLeanConcat2 " " (psPrintJoin " " fields);
          Except.ok (psPrintLeanConcat3 "  | " name suffix)

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
                        else psPrintLeanConcat2 " " (psPrintJoin " " printedBinders);
                      Except.ok
                        (psPrintLeanConcat6
                          "def "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintLeanConcat2 " := " printedValue))
  | .partialDefinition name binders type value _ =>
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
                        else psPrintLeanConcat2 " " (psPrintJoin " " printedBinders);
                      Except.ok
                        (psPrintLeanConcat6
                          "partial def "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintLeanConcat2 " := " printedValue))
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
                        else psPrintLeanConcat2 " " (psPrintJoin " " printedBinders);
                      Except.ok
                        (psPrintLeanConcat6
                          "theorem "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintLeanConcat2 " := " printedValue))
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
                        Except.ok (psPrintLeanConcat2 " : " printed);
              match printResult with
              | Except.error error => Except.error error
              | Except.ok printedResult =>
                  match constructors.mapM psPrintLeanConstructor with
                  | Except.error error => Except.error error
                  | Except.ok printedConstructors =>
                      let paramSuffix :=
                        if printedParams.isEmpty then ""
                        else psPrintLeanConcat2 " " (psPrintJoin " " printedParams);
                      Except.ok
                        (psPrintLeanConcat6
                          "inductive "
                          printedName
                          paramSuffix
                          printedResult
                          " where\n"
                          (psPrintJoin "\n" printedConstructors))
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
                    else psPrintLeanConcat2 " " (psPrintJoin " " printedParams);
                  Except.ok
                    (psPrintLeanConcat5
                      "structure "
                      printedName
                      paramSuffix
                      " where\n"
                      (psPrintJoin "\n" printedFields))

def psPrintLeanModule
    (module : PsSyntaxModule) :
    Except PsSourcePrintError String :=
  let printImport :=
    fun (sourceImport : PsSyntaxImport) =>
      match psPrintSyntaxName sourceImport.moduleName with
      | Except.error error => Except.error error
      | Except.ok name =>
          Except.ok (psPrintLeanConcat2 "import " name);
  match module.imports.mapM printImport with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match module.declarations.mapM psPrintLeanDeclaration with
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
              (psPrintLeanConcat2
                (psPrintJoin "\n\n" sections)
                "\n")
