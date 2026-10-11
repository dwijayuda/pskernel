import Ps.Syntax.Pscv0.Module

-- Compiler source/AST tests only. Fixtures are syntactic, not proof admissions.
def m1Shape (fuel : Nat) (term : PsSyntaxTerm) : String :=
  match fuel with
  | 0 => "budget"
  | n + 1 =>
    let shape := m1Shape n
    match term with
    | .reference name => psPscv0NameText name
    | .sortE isType level _ => psPrintSyntaxSort isType level
    | .call fn args _ => "app(" ++ shape fn ++ ";" ++ String.intercalate ", " (args.map (fun a => shape a.snd)) ++ ")"
    | .app fn args _ => "app(" ++ shape fn ++ ";" ++ String.intercalate ", " (args.map shape) ++ ")"
    | .forallE binders body _ =>
      "pi(" ++ String.intercalate ", " (binders.map (fun b => shape b.snd)) ++ ";" ++ shape body ++ ")"
    | .letE _ type value body _ =>
      "let(" ++ (match type with | none => "_" | some t => shape t) ++ ";" ++ shape value ++ ";" ++ shape body ++ ")"
    | _ => "other"

def m1Locals (fuel : Nat) (term : PsSyntaxTerm) : List String :=
  match fuel with
  | 0 => ["budget"]
  | n + 1 =>
    let own := match term with
      | .letE _ (some type) _ _ _ => [m1Shape 4096 type]
      | _ => []
    own ++ (psPscv0TermChildren term).flatMap (m1Locals n)

def m1Spans (fuel size : Nat) (term : PsSyntaxTerm) : Bool :=
  match fuel with
  | 0 => false
  | n + 1 =>
    let span := psSyntaxTermSpan term
    span.start.byteOffset <= span.stop.byteOffset &&
      span.stop.byteOffset <= size &&
      (psPscv0TermChildren term).all (m1Spans n size)

def m1Good (name source result : String) (locals : List String) : IO Unit := do
  let surface ← match psPscv0ParseSource true source with
    | .ok x => pure x
    | .error e => throw (IO.userError (name ++ ": " ++ e))
  unless psPscv0ReplayOriginal surface == source do
    throw (IO.userError (name ++ ": source replay"))
  let declaration ← match surface.declarations with
    | [x] => pure x
    | _ => throw (IO.userError (name ++ ": declaration count"))
  let (type, value) ← match declaration.declaration with
    | .definition _ _ t v _ | .theoremDecl _ _ t v _ => pure (t, v)
    | _ => throw (IO.userError (name ++ ": declaration kind"))
  unless m1Shape 4096 type == result do
    throw (IO.userError (name ++ ": result tree: " ++ m1Shape 4096 type))
  let doLocals := match declaration.doBody with
    | none => []
    | some block => block.items.flatMap fun item =>
      match item with
      | .letValue _ type value _ =>
        (match type with | none => [] | some t => [m1Shape 4096 t]) ++ m1Locals 4096 value
      | .bind _ action _ | .action action _ | .returnValue action _ => m1Locals 4096 action
  let found := m1Locals 4096 value ++ doLocals
  unless found == locals do
    throw (IO.userError (name ++ ": local trees: " ++ reprStr found))
  unless m1Spans 4096 source.utf8ByteSize type && m1Spans 4096 source.utf8ByteSize value do
    throw (IO.userError (name ++ ": source span bounds"))
  IO.println ("PSCV0_M1_NATIVE_CASE: PASS " ++ name)

def m1Bad (name source errorPrefix : String) : IO Unit := do
  match psPscv0ParseSource true source with
  | .ok _ => throw (IO.userError (name ++ ": invalid source accepted"))
  | .error error =>
    unless errorPrefix.isPrefixOf error do
      throw (IO.userError (name ++ ": " ++ error))
    IO.println ("PSCV0_M1_NATIVE_REFUSAL: PASS " ++ name)
