import Ps.BackendJs.Model
import Ps.BackendJs.PortableText

def psJsNatDecimal (value : Nat) : Except PsJsError String :=
  Except.ok (Int.repr (Int.ofNat value))

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
  | PsJsLiteral.machineNumber number => psJsIntDecimal number
  | PsJsLiteral.machineBigInt number =>
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
          | List.cons _restHead _restTail =>
              match psJsEmitParameterNames rest with
              | Except.error error => Except.error error
              | Except.ok names =>
                  Except.ok (psJsTextConcat3 name ", " names)

def psJsEmitNatIntrinsic (operation : PsJsIntrinsic)
    (left right : String) : String :=
  match operation with
  | PsJsIntrinsic.natAdd => psJsTextConcat3 (psJsTextConcat2 "(" left) " + " (psJsTextConcat2 right ")")
  | PsJsIntrinsic.natSub =>
      psJsTextConcat3
        "((__psc_a, __psc_b) => (__psc_a >= __psc_b ? __psc_a - __psc_b : 0n))("
        (psJsTextConcat3 left ", " right)
        ")"
  | PsJsIntrinsic.natMul => psJsTextConcat3 (psJsTextConcat2 "(" left) " * " (psJsTextConcat2 right ")")
  | PsJsIntrinsic.natDiv =>
      psJsTextConcat3
        "((__psc_a, __psc_b) => (__psc_b === 0n ? 0n : __psc_a / __psc_b))("
        (psJsTextConcat3 left ", " right)
        ")"
  | PsJsIntrinsic.natMod =>
      psJsTextConcat3
        "((__psc_a, __psc_b) => (__psc_b === 0n ? __psc_a : __psc_a % __psc_b))("
        (psJsTextConcat3 left ", " right)
        ")"
  | PsJsIntrinsic.natEq => psJsTextConcat3 (psJsTextConcat2 "(" left) " === " (psJsTextConcat2 right ")")
  | PsJsIntrinsic.natNe => psJsTextConcat3 (psJsTextConcat2 "(" left) " !== " (psJsTextConcat2 right ")")
  | PsJsIntrinsic.natLe => psJsTextConcat3 (psJsTextConcat2 "(" left) " <= " (psJsTextConcat2 right ")")
  | PsJsIntrinsic.natLt => psJsTextConcat3 (psJsTextConcat2 "(" left) " < " (psJsTextConcat2 right ")")

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

def psJsEmitAtomicArguments (callArguments : List PsJsExpr) : Except PsJsError String :=
  match callArguments with
  | List.nil => Except.ok ""
  | List.cons argument rest =>
      match psJsEmitAtomicExpr argument with
      | Except.error error => Except.error error
      | Except.ok printedArgument =>
          match rest with
          | List.nil => Except.ok printedArgument
          | List.cons _restHead _restTail =>
              match psJsEmitAtomicArguments rest with
              | Except.error error => Except.error error
              | Except.ok printedRest =>
                  Except.ok (psJsTextConcat3 printedArgument ", " printedRest)

def psJsEmitExpr (expr : PsJsExpr) : Except PsJsError String :=
  match expr with
  | PsJsExpr.literal value => psJsEmitLiteral value
  | PsJsExpr.local index => psJsLocalName index
  | PsJsExpr.global index => psJsGlobalName index
  | PsJsExpr.intrinsic operation arguments =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          match psJsEmitExpr left with
          | Except.error error => Except.error error
          | Except.ok printedLeft =>
              match psJsEmitExpr right with
              | Except.error error => Except.error error
              | Except.ok printedRight =>
                  Except.ok (psJsEmitNatIntrinsic operation printedLeft printedRight)
      | _ => Except.error PsJsError.unsupportedExpression
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
  | PsJsExpr.call fn callArguments =>
      match fn with
      | PsJsExpr.global index =>
          match callArguments with
          | List.nil => Except.error PsJsError.unsupportedExpression
          | List.cons _firstArgument _restArguments =>
              match psJsGlobalName index with
              | Except.error error => Except.error error
              | Except.ok printedFn =>
                  match psJsEmitAtomicArguments callArguments with
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

def psJsEmitConstantsWithFuel (fuel : Nat) :
    List PsJsConstant -> Nat -> Except PsJsError String :=
  match fuel with
  | Nat.zero =>
      fun (_constants : List PsJsConstant) =>
        fun (_index : Nat) => Except.error PsJsError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : List PsJsConstant -> Nat -> Except PsJsError String :=
        psJsEmitConstantsWithFuel remaining;
      fun (constants : List PsJsConstant) =>
        fun (index : Nat) =>
          match constants with
          | List.nil => Except.ok ""
          | List.cons constant rest =>
              match psJsGlobalName index with
              | Except.error error => Except.error error
              | Except.ok internalName =>
                  match psJsEmitExpr constant.body with
                  | Except.error error => Except.error error
                  | Except.ok printedBody =>
                      match smaller rest (Nat.succ index) with
                      | Except.error error => Except.error error
                      | Except.ok printedRest =>
                          let definition :=
                            psJsTextConcat3 "const " internalName " = ";
                          let value :=
                            psJsTextConcat3 definition printedBody ";\n";
                          let exportStart :=
                            psJsTextConcat3 "export { " internalName " as ";
                          let exportLine :=
                            psJsTextConcat3 exportStart constant.exportName " };\n";
                          Except.ok
                            (psJsTextConcat3 value exportLine printedRest)

def psJsEmitConstants (constants : List PsJsConstant)
    (index : Nat) : Except PsJsError String :=
  psJsEmitConstantsWithFuel 4096 constants index

def psJsEmitTargetModule (module : PsJsModule) : Except PsJsError String :=
  match psJsEmitConstants module.constants 0 with
  | Except.error error => Except.error error
  | Except.ok constants =>
      Except.ok
        (psJsTextConcat2
          "// Generated by ProofScript backend-js (lexical profile).\nexport {};\n"
          constants)
