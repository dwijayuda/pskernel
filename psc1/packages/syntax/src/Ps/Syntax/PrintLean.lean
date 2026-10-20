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

def psPrintLeanSpaceJoinedSuffix
    (values : List String) : String :=
  match values with
  | List.nil => ""
  | List.cons _ _ =>
      psPrintLeanConcat2 " " (psPrintJoin " " values)

def psPrintLeanMapRecordFields
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
            psPrintLeanMapRecordFields printField rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintLeanMapTerms
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
            psPrintLeanMapTerms printTerm rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintLeanMapBinders
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
            psPrintLeanMapBinders printBinder rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintLeanMapAlternatives
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
            psPrintLeanMapAlternatives printAlternative rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintLeanMapConstructors
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
            psPrintLeanMapConstructors printConstructor rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintLeanMapImports
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
            psPrintLeanMapImports printImport rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintLeanMapDeclarations
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
            psPrintLeanMapDeclarations printDeclaration rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

def psPrintLeanTermWithFuel
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
        psPrintLeanTermWithFuel remaining;
      match term with
      | PsSyntaxTerm.reference name =>
          psPrintSyntaxName name
      | PsSyntaxTerm.natural text _ =>
          Except.ok text
      | PsSyntaxTerm.string text _ =>
          Except.ok text
      | PsSyntaxTerm.character text _ =>
          Except.ok text
      | PsSyntaxTerm.bool value _ =>
          if value then
            Except.ok "true"
          else
            Except.ok "false"
      | PsSyntaxTerm.unit _ =>
          Except.ok "()"
      | PsSyntaxTerm.record fields _ =>
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
          let printedFieldsResult :
              Except PsSourcePrintError (List String) :=
            psPrintLeanMapRecordFields printField fields;
          match printedFieldsResult with
          | Except.error error => Except.error error
          | Except.ok printedFields =>
              Except.ok
                (psPrintLeanConcat3 "{ " (psPrintJoin ", " printedFields) " }")
      | PsSyntaxTerm.app fn args _ =>
          if psPrintLeanBoolNot (psSyntaxTermSimpleForApplication fn) then
            Except.error PsSourcePrintError.unsupportedApplication
          else
            match smaller fn with
            | Except.error error => Except.error error
            | Except.ok printedFn =>
                let printArgument :
                    PsSyntaxTerm -> Except PsSourcePrintError String :=
                  fun (arg : PsSyntaxTerm) =>
                    match smaller arg with
                    | Except.error error => Except.error error
                    | Except.ok printed =>
                        if psSyntaxTermSimpleForApplication arg then
                          Except.ok printed
                        else
                          Except.ok (psPrintLeanConcat3 "(" printed ")");
                let printedArgsResult :
                    Except PsSourcePrintError (List String) :=
                  psPrintLeanMapTerms printArgument args;
                match printedArgsResult with
                | Except.error error => Except.error error
                | Except.ok printedArgs =>
                    match printedArgs with
                    | List.nil =>
                        Except.ok printedFn
                    | List.cons _ _ =>
                        Except.ok
                          (psPrintLeanConcat3
                            printedFn
                            " "
                            (psPrintJoin " " printedArgs))
      | PsSyntaxTerm.unary operator operand _ =>
          psPrintUnaryOperator smaller operator operand
      | PsSyntaxTerm.binary operator left right _ =>
          psPrintBinaryOperator smaller operator left right
      | PsSyntaxTerm.arrayGetOptionE array index _ =>
          match smaller array with
          | Except.error error => Except.error error
          | Except.ok printedArray =>
              match smaller index with
              | Except.error error => Except.error error
              | Except.ok printedIndex =>
                  Except.ok (psPrintJoin "" ["(", printedArray, ")[", printedIndex, "]?"])
      | PsSyntaxTerm.doE body _ =>
          match psPrintDoBody smaller true "; " remaining body with
          | Except.error error => Except.error error
          | Except.ok printed =>
              Except.ok (psPrintCommonConcat3 "do { " printed " }")
      | PsSyntaxTerm.doBindE _ _ _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "do bind outside do block")
      | PsSyntaxTerm.doThenE _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "do action outside do block")
      | PsSyntaxTerm.doLetMutE _ _ _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "mutable binding outside do block")
      | PsSyntaxTerm.doAssignE _ _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "assignment outside do block")
      | PsSyntaxTerm.doIfE _ _ _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "procedural conditional outside do block")
      | PsSyntaxTerm.doEndE _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "procedural continuation outside do block")
      | PsSyntaxTerm.doForE _ _ _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "for statement outside do block")
      | PsSyntaxTerm.doForRangeE _ _ _ _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "range iteration outside do block")
      | PsSyntaxTerm.doTryE _ _ _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "try statement outside do block")
      | PsSyntaxTerm.doWhileE _ _ _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "while statement outside do block")
      | PsSyntaxTerm.doReturnE _ _ =>
          Except.error (PsSourcePrintError.unsupportedSourceForm "return outside do block")
      | PsSyntaxTerm.lambda binders body _ =>
          let printBinder :
              Prod PsSyntaxBinderHead PsSyntaxTerm ->
                Except PsSourcePrintError String :=
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
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintLeanMapBinders printBinder binders;
          match printedBindersResult with
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
      | PsSyntaxTerm.forallE binders body _ =>
          let printBinder :
              Prod PsSyntaxBinderHead PsSyntaxTerm ->
                Except PsSourcePrintError String :=
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
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintLeanMapBinders printBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match smaller body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    (psPrintArrowChain printedBinders printedBody)
      | PsSyntaxTerm.letPatternE pattern type value body _ =>
          match psPrintBindingPatternHead smaller pattern type value with
          | Except.error error => Except.error error
          | Except.ok head =>
              match smaller body with
              | Except.error error => Except.error error
              | Except.ok tail => Except.ok (psPrintLeanConcat3 head "; " tail)
      | PsSyntaxTerm.letE name type value body _ =>
          match psPrintSyntaxName name with
          | Except.error error => Except.error error
          | Except.ok printedName =>
              let printType :
                  Except PsSourcePrintError String :=
                match type with
                | none => Except.ok ""
                | some declaredType =>
                    match smaller declaredType with
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
      | PsSyntaxTerm.ifE condition thenBranch elseBranch _ =>
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
      | PsSyntaxTerm.matchE scrutinee alternatives _ =>
          match smaller scrutinee with
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
                                    (psPrintLeanConcat4
                                      "  | "
                                      printedPattern
                                      " => "
                                      printedBody);
              let printedAlternativesResult :
                  Except PsSourcePrintError (List String) :=
                psPrintLeanMapAlternatives
                  printAlternative
                  alternatives;
              match printedAlternativesResult with
              | Except.error error => Except.error error
              | Except.ok printedAlternatives =>
                  match printedAlternatives with
                  | List.nil =>
                      Except.ok (psPrintLeanConcat2 "nomatch " printedScrutinee)
                  | List.cons _ _ =>
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
              let value : String :=
                match head.kind with
                | PsSyntaxBinderKind.explicit => psPrintLeanConcat3 name " : " printedType
                | PsSyntaxBinderKind.implicit => psPrintLeanConcat5 "{" name " : " printedType "}"
                | PsSyntaxBinderKind.strictImplicit => psPrintLeanConcat5 "{{" name " : " printedType "}}"
                | PsSyntaxBinderKind.instanceImplicit => psPrintLeanConcat5 "[" name " : " printedType "]";
              Except.ok (psPrintLeanConcat2 "  " value)

def psPrintLeanConstructor
    (constructor : PsSyntaxInductiveConstructor) :
    Except PsSourcePrintError String :=
  match psPrintSyntaxName constructor.name with
  | Except.error error => Except.error error
  | Except.ok name =>
      let fieldsResult :
          Except PsSourcePrintError (List String) :=
        psPrintLeanMapBinders
          psPrintLeanBinder
          constructor.fields;
      match fieldsResult with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let suffix : String :=
            match fields with
            | List.nil => ""
            | List.cons _ _ =>
                psPrintLeanConcat2 " " (psPrintJoin " " fields);
          Except.ok (psPrintLeanConcat3 "  | " name suffix)

def psPrintLeanDeclaration
    (declaration : PsSyntaxDeclaration) :
    Except PsSourcePrintError String :=
  match declaration with
  | PsSyntaxDeclaration.scopedDecl path inner =>
      match path with
      | [] => psPrintLeanDeclaration inner
      | List.cons _ _ =>
          match psPrintLeanDeclaration inner with
          | Except.error error => Except.error error
          | Except.ok body =>
              let name := psPrintJoin "." path;
              Except.ok (psPrintLeanConcat6
                "namespace " name "\n" body "\nend " name)
  | PsSyntaxDeclaration.definition name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintLeanMapBinders psPrintLeanBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintLeanTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintLeanTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        psPrintLeanSpaceJoinedSuffix printedBinders;
                      Except.ok
                        (psPrintLeanConcat6
                          "def "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintLeanConcat2 " := " printedValue))
  | PsSyntaxDeclaration.partialDefinition name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintLeanMapBinders psPrintLeanBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintLeanTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintLeanTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        psPrintLeanSpaceJoinedSuffix printedBinders;
                      Except.ok
                        (psPrintLeanConcat6
                          "partial def "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintLeanConcat2 " := " printedValue))
  | PsSyntaxDeclaration.theoremDecl name binders type value _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            psPrintLeanMapBinders psPrintLeanBinder binders;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match psPrintLeanTerm type with
              | Except.error error => Except.error error
              | Except.ok printedType =>
                  match psPrintLeanTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      let binderSuffix :=
                        psPrintLeanSpaceJoinedSuffix printedBinders;
                      Except.ok
                        (psPrintLeanConcat6
                          "theorem "
                          printedName
                          binderSuffix
                          " : "
                          printedType
                          (psPrintLeanConcat2 " := " printedValue))
  | PsSyntaxDeclaration.inductiveDecl name params resultType constructors _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedParamsResult :
              Except PsSourcePrintError (List String) :=
            psPrintLeanMapBinders psPrintLeanBinder params;
          match printedParamsResult with
          | Except.error error => Except.error error
          | Except.ok printedParams =>
              let printResult :
                  Except PsSourcePrintError String :=
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
                  let printedConstructorsResult :
                      Except PsSourcePrintError (List String) :=
                    psPrintLeanMapConstructors
                      psPrintLeanConstructor
                      constructors;
                  match printedConstructorsResult with
                  | Except.error error => Except.error error
                  | Except.ok printedConstructors =>
                      let paramSuffix :=
                        psPrintLeanSpaceJoinedSuffix printedParams;
                      Except.ok
                        (psPrintLeanConcat6
                          "inductive "
                          printedName
                          paramSuffix
                          printedResult
                          " where\n"
                          (psPrintJoin "\n" printedConstructors))
  | PsSyntaxDeclaration.structureDecl name params fields _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedParamsResult :
              Except PsSourcePrintError (List String) :=
            psPrintLeanMapBinders psPrintLeanBinder params;
          match printedParamsResult with
          | Except.error error => Except.error error
          | Except.ok printedParams =>
              let printedFieldsResult :
                  Except PsSourcePrintError (List String) :=
                psPrintLeanMapBinders
                  psPrintLeanStructureField
                  fields;
              match printedFieldsResult with
              | Except.error error => Except.error error
              | Except.ok printedFields =>
                  let paramSuffix :=
                    psPrintLeanSpaceJoinedSuffix printedParams;
                  Except.ok
                    (psPrintLeanConcat5
                      "structure "
                      printedName
                      paramSuffix
                      " where\n"
                      (psPrintJoin "\n" printedFields))

def psPrintLeanImport
    (sourceImport : PsSyntaxImport) :
    Except PsSourcePrintError String :=
  let printedNameResult :=
    psPrintSyntaxName sourceImport.moduleName;
  match printedNameResult with
  | Except.error error => Except.error error
  | Except.ok name =>
      Except.ok (psPrintLeanConcat2 "import " name)

def psPrintLeanAppendStrings
    (xs : List String) : List String -> List String :=
  match xs with
  | List.nil =>
      fun (ys : List String) => ys
  | List.cons head tail =>
      let smaller : List String -> List String :=
        psPrintLeanAppendStrings tail;
      fun (ys : List String) =>
        List.cons head (smaller ys)

def psPrintLeanModuleParts
    (sourceImports : List PsSyntaxImport)
    (sourceDeclarations : List PsSyntaxDeclaration) :
    Except PsSourcePrintError String :=
  let importsResult :
      Except PsSourcePrintError (List String) :=
    psPrintLeanMapImports psPrintLeanImport sourceImports;
  match importsResult with
  | Except.error error => Except.error error
  | Except.ok imports =>
      let declarationsResult :
          Except PsSourcePrintError (List String) :=
        psPrintLeanMapDeclarations
          psPrintLeanDeclaration
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
            psPrintLeanAppendStrings
              importSections
              declarationSections;
          match sections with
          | List.nil =>
              Except.ok ""
          | List.cons _ _ =>
              Except.ok
                (psPrintLeanConcat2
                  (psPrintJoin "\n\n" sections)
                  "\n")

def psPrintLeanModule
    (module : PsSyntaxModule) :
    Except PsSourcePrintError String :=
  match module with
  | PsSyntaxModule.mk sourceImports sourceDeclarations =>
      psPrintLeanModuleParts sourceImports sourceDeclarations
