import Ps.BackendJs.Model
import Ps.BackendJs.PortableText

def psJsNatDecimalWithFuel (fuel : Nat) : Nat -> Except PsJsError String :=
  match fuel with
  | Nat.zero =>
      fun (_value : Nat) => Except.error PsJsError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : Nat -> Except PsJsError String :=
        psJsNatDecimalWithFuel remaining;
      fun (value : Nat) =>
        if Nat.blt value 10 then
          Except.ok (psJsTextHexDigit value)
        else
          match smaller (Nat.div value 10) with
          | Except.error error => Except.error error
          | Except.ok higherDigits =>
              Except.ok
                (psJsTextConcat2 higherDigits (psJsTextHexDigit (Nat.mod value 10)))

def psJsNatDecimal (value : Nat) : Except PsJsError String :=
  psJsNatDecimalWithFuel (Nat.succ value) value

def psJsIntDecimal (value : Int) : Except PsJsError String :=
  Except.ok (Int.repr value)

def psJsEmitLiteral (value : PsJsLiteral) : Except PsJsError String :=
  match value with
  | PsJsLiteral.natural number =>
      match psJsNatDecimal number with
      | Except.error error => Except.error error
      | Except.ok text => Except.ok (psJsTextConcat2 text "n")
  | PsJsLiteral.integer number =>
      match psJsIntDecimal number with
      | Except.error error => Except.error error
      | Except.ok text => Except.ok (psJsTextConcat2 text "n")
  | PsJsLiteral.boolean boolean =>
      if boolean then Except.ok "true"
      else Except.ok "false"
  | PsJsLiteral.string text => Except.ok (psJsTextQuote text)
  | PsJsLiteral.undefined => Except.ok "undefined"

def psJsLocalName (index : Nat) : Except PsJsError String :=
  match psJsNatDecimal index with
  | Except.error error => Except.error error
  | Except.ok text => Except.ok (psJsTextConcat2 "__psc_js_l_" text)

def psJsGlobalName (index : Nat) : Except PsJsError String :=
  match psJsNatDecimal index with
  | Except.error error => Except.error error
  | Except.ok text => Except.ok (psJsTextConcat2 "__psc_js_" text)

def psJsEmitParameterNames (parameters : List Nat) : Except PsJsError String :=
  match parameters with
  | List.nil => Except.ok ""
  | List.cons index rest =>
      match psJsLocalName index with
      | Except.error error => Except.error error
      | Except.ok name =>
          match rest with
          | List.nil => Except.ok name
          | List.cons _ _ =>
              match psJsEmitParameterNames rest with
              | Except.error error => Except.error error
              | Except.ok names =>
                  Except.ok (psJsTextConcat3 name ", " names)

def psJsEmitAtomicExpr (expr : PsJsExpr) : Except PsJsError String :=
  match expr with
  | PsJsExpr.literal value => psJsEmitLiteral value
  | PsJsExpr.local index => psJsLocalName index
  | PsJsExpr.global index => psJsGlobalName index
  | PsJsExpr.letE index value body =>
      match psJsLocalName index with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psJsEmitAtomicExpr body with
          | Except.error error => Except.error error
          | Except.ok printedBody =>
              match psJsEmitAtomicExpr value with
              | Except.error error => Except.error error
              | Except.ok printedValue =>
                  let start := psJsTextConcat3 "((" name ") => ";
                  let withBody := psJsTextConcat3 start printedBody ")(";
                  Except.ok (psJsTextConcat3 withBody printedValue ")")
  | PsJsExpr.ifE condition thenBranch elseBranch =>
      match psJsEmitAtomicExpr condition with
      | Except.error error => Except.error error
      | Except.ok printedCondition =>
          match psJsEmitAtomicExpr thenBranch with
          | Except.error error => Except.error error
          | Except.ok printedThen =>
              match psJsEmitAtomicExpr elseBranch with
              | Except.error error => Except.error error
              | Except.ok printedElse =>
                  let start := psJsTextConcat2 "(" printedCondition;
                  let withThen := psJsTextConcat3 start " ? " printedThen;
                  let withElse := psJsTextConcat3 withThen " : " printedElse;
                  Except.ok (psJsTextConcat2 withElse ")")
  | _ => Except.error PsJsError.unsupportedExpression

def psJsEmitAtomicArguments (arguments : List PsJsExpr) : Except PsJsError String :=
  match arguments with
  | List.nil => Except.ok ""
  | List.cons argument rest =>
      match psJsEmitAtomicExpr argument with
      | Except.error error => Except.error error
      | Except.ok printedArgument =>
          match rest with
          | List.nil => Except.ok printedArgument
          | List.cons _ _ =>
              match psJsEmitAtomicArguments rest with
              | Except.error error => Except.error error
              | Except.ok printedRest =>
                  Except.ok (psJsTextConcat3 printedArgument ", " printedRest)

def psJsEmitExpr (expr : PsJsExpr) : Except PsJsError String :=
  match expr with
  | PsJsExpr.literal value => psJsEmitLiteral value
  | PsJsExpr.local index => psJsLocalName index
  | PsJsExpr.global index => psJsGlobalName index
  | PsJsExpr.letE index value body =>
      match psJsLocalName index with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psJsEmitExpr body with
          | Except.error error => Except.error error
          | Except.ok printedBody =>
              match psJsEmitExpr value with
              | Except.error error => Except.error error
              | Except.ok printedValue =>
                  let start := psJsTextConcat3 "((" name ") => ";
                  let withBody := psJsTextConcat3 start printedBody ")(";
                  Except.ok (psJsTextConcat3 withBody printedValue ")")
  | PsJsExpr.lambda parameters body =>
      match psJsEmitParameterNames parameters with
      | Except.error error => Except.error error
      | Except.ok names =>
          match psJsEmitExpr body with
          | Except.error error => Except.error error
          | Except.ok printedBody =>
              let start := psJsTextConcat3 "((" names ") => ";
              Except.ok (psJsTextConcat3 start printedBody ")")
  | PsJsExpr.call fn arguments =>
      match fn with
      | PsJsExpr.global index =>
          match arguments with
          | List.nil => Except.error PsJsError.unsupportedExpression
          | List.cons _ _ =>
              match psJsGlobalName index with
              | Except.error error => Except.error error
              | Except.ok printedFn =>
                  match psJsEmitAtomicArguments arguments with
                  | Except.error error => Except.error error
                  | Except.ok printedArguments =>
                      let start := psJsTextConcat2 "(" printedFn;
                      let middle := psJsTextConcat3 start ")(" printedArguments;
                      Except.ok (psJsTextConcat2 middle ")")
      | _ => Except.error PsJsError.unsupportedExpression
  | PsJsExpr.ifE condition thenBranch elseBranch =>
      match psJsEmitExpr condition with
      | Except.error error => Except.error error
      | Except.ok printedCondition =>
          match psJsEmitExpr thenBranch with
          | Except.error error => Except.error error
          | Except.ok printedThen =>
              match psJsEmitExpr elseBranch with
              | Except.error error => Except.error error
              | Except.ok printedElse =>
                  let start := psJsTextConcat2 "(" printedCondition;
                  let withThen := psJsTextConcat3 start " ? " printedThen;
                  let withElse := psJsTextConcat3 withThen " : " printedElse;
                  Except.ok (psJsTextConcat2 withElse ")")

def psJsEmitConstants (constants : List PsJsConstant) :
    Nat -> Except PsJsError String :=
  match constants with
  | List.nil =>
      fun (_index : Nat) => Except.ok ""
  | List.cons constant rest =>
      let smaller : Nat -> Except PsJsError String := psJsEmitConstants rest;
      fun (index : Nat) =>
        match psJsGlobalName index with
        | Except.error error => Except.error error
        | Except.ok internalName =>
            match psJsEmitExpr constant.body with
            | Except.error error => Except.error error
            | Except.ok printedBody =>
                match smaller (Nat.succ index) with
                | Except.error error => Except.error error
                | Except.ok printedRest =>
                    let definition := psJsTextConcat3 "const " internalName " = ";
                    let value := psJsTextConcat3 definition printedBody ";\n";
                    let exportStart := psJsTextConcat3 "export { " internalName " as ";
                    let exportLine := psJsTextConcat3 exportStart constant.exportName " };\n";
                    Except.ok (psJsTextConcat3 value exportLine printedRest)

def psJsEmitTargetModule (module : PsJsModule) : Except PsJsError String :=
  match psJsEmitConstants module.constants 0 with
  | Except.error error => Except.error error
  | Except.ok constants =>
      Except.ok
        (psJsTextConcat2
          "// Generated by ProofScript backend-js (lexical profile).\nexport {};\n"
          constants)
