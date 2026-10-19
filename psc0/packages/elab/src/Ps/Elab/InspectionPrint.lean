import Ps.Elab.InspectionDependencies

def psInspectionName (name : PsName) : String :=
  match name with
  | .anonymous => "_"
  | .str parent value =>
    let segment := if value.contains '.' || value.contains ' ' || value.isEmpty then
        "«" ++ value ++ "»" else value
    match parent with
    | .anonymous => segment
    | _ => psInspectionName parent ++ "." ++ segment
  | .num parent value => psInspectionName parent ++ "." ++ toString value

def psInspectionLevel (fuel : Nat) (level : PsLevel) : Except PsElabError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match level with
    | .zero => return "0"
    | .succ .zero => return "1"
    | .succ value => return "(" ++ (← psInspectionLevel fuel value) ++ " + 1)"
    | .max left right => return "max " ++ (← psInspectionLevel fuel left) ++ " " ++
        (← psInspectionLevel fuel right)
    | .imax left right => return "imax " ++ (← psInspectionLevel fuel left) ++ " " ++
        (← psInspectionLevel fuel right)
    | .param name => return psInspectionName name
    | .mvar id => return "?u" ++ toString id

def psInspectionBinder (name type : String) (binder : PsBinderInfo) : String :=
  match binder with
  | .implicit => "{" ++ name ++ " : " ++ type ++ "}"
  | .strictImplicit => "⦃" ++ name ++ " : " ++ type ++ "⦄"
  | .instanceImplicit => "[" ++ name ++ " : " ++ type ++ "]"
  | .explicit => "(" ++ name ++ " : " ++ type ++ ")"

def psInspectionExpr (fuel : Nat) (locals : PsLocalContext) (bound : List String)
    (expression : PsExpr) : Except PsElabError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let visit := psInspectionExpr fuel locals bound
    match expression with
    | .bvar index =>
      match bound[index]? with
      | some name => return name
      | none => return "#b" ++ toString index
    | .fvar id =>
      return match psLocalFindById locals id with
        | some declaration => psInspectionName (psLocalDeclUserName declaration)
        | none => "#f" ++ toString id
    | .mvar id => return "?m" ++ toString id
    | .sortE .zero => return "Prop"
    | .sortE (.succ .zero) => return "Type"
    | .sortE (.succ level) => return "Type " ++ (← psInspectionLevel fuel level)
    | .sortE level => return "Sort " ++ (← psInspectionLevel fuel level)
    | .constE name levels =>
      let suffix ← if levels.isEmpty then pure "" else do
        let levels ← levels.mapM (psInspectionLevel fuel)
        pure (".{" ++ String.intercalate ", " levels ++ "}")
      return psInspectionName name ++ suffix
    | .app fn argument => return "(" ++ (← visit fn) ++ " " ++ (← visit argument) ++ ")"
    | .lam name type body binder =>
      let name := psInspectionName name
      return "(fun " ++ psInspectionBinder name (← visit type) binder ++ " => " ++
        (← psInspectionExpr fuel locals (name :: bound) body) ++ ")"
    | .forallE name type body binder =>
      let name := psInspectionName name
      return "(∀ " ++ psInspectionBinder name (← visit type) binder ++ ", " ++
        (← psInspectionExpr fuel locals (name :: bound) body) ++ ")"
    | .letE name type value body =>
      let name := psInspectionName name
      return "(let " ++ name ++ " : " ++ (← visit type) ++ " := " ++ (← visit value) ++
        "; " ++ (← psInspectionExpr fuel locals (name :: bound) body) ++ ")"
    | .lit (.natural value) => return toString value
    | .lit (.string value) => return String.quote value
    | .proj owner index major =>
      return "(" ++ (← visit major) ++ ")." ++ psInspectionName owner ++ "." ++ toString index

def psInspectionPrintDeclaration (environment : PsEnvironment) (declaration : PsDeclaration) :
    Except PsElabError String := do
  let kind := match declaration with
    | .axiomDecl .. => "axiom" | .definitionDecl .. => "def"
    | .theoremDecl .. => "theorem" | .partialDecl .. => "partial def"
    | .opaqueDecl .. => "opaque" | .quotientDecl .. => "quotient"
    | .inductiveDecl info => if info.isStructure then "structure" else "inductive"
    | .constructorDecl .. => "constructor" | .recursorDecl .. => "recursor"
  let universes := psDeclarationLevelParams declaration
  let suffix := if universes.isEmpty then "" else
    ".{" ++ String.intercalate ", " (universes.map psInspectionName) ++ "}"
  let header := kind ++ " " ++ psInspectionName (psDeclarationName declaration) ++ suffix ++
    " : " ++ (← psInspectionExpr 4096 psLocalEmpty [] (psDeclarationType declaration))
  match declaration with
  | .definitionDecl _ _ _ body | .theoremDecl _ _ _ body =>
    return header ++ " :=\n" ++ (← psInspectionExpr 4096 psLocalEmpty [] body)
  | .inductiveDecl info =>
    let constructors ← info.constructors.mapM fun name => do
      let some declaration := psEnvironmentFind environment name
        | throw (psInspectionError ("missing registered constructor " ++ psInspectionName name))
      return psInspectionName name ++ " : " ++
        (← psInspectionExpr 4096 psLocalEmpty [] (psDeclarationType declaration))
    return header ++ "\n" ++ String.intercalate "\n" constructors
  | _ => return header

def psInspectionPrintAxioms (environment : PsEnvironment) (name : PsName) :
    Except PsElabError String := do
  let actual ← (psInspectionExecutionEnvironment environment).mapError psInspectionError
  let axioms ← psInspectionAxioms 32768 actual [name] [] []
  let names := (axioms.map psInspectionName).mergeSort (fun a b => a ≤ b)
  if names.isEmpty then return "'" ++ psInspectionName name ++ "' does not depend on any axioms"
  return "'" ++ psInspectionName name ++ "' depends on axioms: [" ++
    String.intercalate ", " names ++ "]"
