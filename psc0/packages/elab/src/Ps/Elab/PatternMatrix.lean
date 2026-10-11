import Ps.Elab.Match

def psElabMatchPatternConstructorName
    (inductiveInfo : PsName)
    (pattern : PsSyntaxPattern) :
    Except PsElabError PsName :=
  match pattern with
  | .bool value _ =>
      if psNameEq inductiveInfo psBoolName then
        if value then
          Except.ok psBoolTrueName
        else
          Except.ok psBoolFalseName
      else
        Except.error PsElabError.matchPatternUnsupported
  | .wildcard _ | .variable _ | .natural _ _ =>
      Except.error PsElabError.matchPatternUnsupported
  | .ctor syntaxName _ _ =>
      match syntaxName.segments with
      | [] => Except.error PsElabError.matchPatternUnsupported
      | segment :: rest =>
          match rest with
          | [] =>
              Except.ok (psNameAppendStr inductiveInfo segment)
          | _ :: _ =>
              match psSyntaxNameToName syntaxName with
              | none => Except.error PsElabError.matchPatternUnsupported
              | some name => Except.ok name

structure PsElabPatternColumn where
  major : PsSyntaxTerm
  value : PsSyntaxTerm

structure PsElabPatternRow where
  patterns : List PsSyntaxPattern
  body : PsSyntaxTerm
  span : PsSourceSpan
  bindings : List (PsSyntaxName × PsSyntaxTerm) := []

def psElabPatternIrrefutable : PsSyntaxPattern -> Bool
  | .variable _ | .wildcard _ => true
  | _ => false

def psElabPatternBind (column : PsElabPatternColumn)
    (pattern : PsSyntaxPattern) (row : PsElabPatternRow) : PsElabPatternRow :=
  match pattern with
  | .variable name => { row with bindings := row.bindings ++ [(name, column.value)] }
  | _ => row

def psElabPatternBody (row : PsElabPatternRow) : PsSyntaxTerm :=
  row.bindings.foldr (fun (name, value) body =>
    .letE name none value body row.span) row.body

-- A matrix split delegates its entire typed elimination to Match. Row
-- specialization only changes patterns and lexical aliases; it never constructs
-- a recursor, mutates a dependent type, or assumes an impossible branch.
def psElabPatternMatrix (fuel : Nat) (elaborate : PsElaborator)
    (context : PsElabContext) (columns : List PsElabPatternColumn)
    (rows : List PsElabPatternRow) (expected : PsExpr) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match columns with
    | [] =>
      let some row := rows.head? | throw .matchNonExhaustive
      elaborate context (psElabPatternBody row) (some expected)
    | column :: rest =>
      if rows.isEmpty then
        -- Probe each remaining discriminant for checked impossibility. Do not
        -- recursively expand recursive fields without a pattern to consume.
        let rec eliminate (remaining : List PsElabPatternColumn) :
            Except PsElabError PsElabTermResult := do
          match remaining with
          | [] => throw .matchNonExhaustive
          | column :: remaining =>
            match psElabMatchWith elaborate (fun _ _ => pure []) context column.major (some expected) with
            | .ok result => return result
            | .error .matchNonExhaustive => eliminate remaining
            | .error error => throw error
        return ← eliminate columns
      if rows.all (fun row => (row.patterns.head?.map psElabPatternIrrefutable).getD false) then
        let rows ← rows.mapM fun row => do
          let pattern :: patterns := row.patterns | throw .matchPatternUnsupported
          return { (psElabPatternBind column pattern row) with patterns }
        return ← psElabPatternMatrix fuel elaborate context rest rows expected
      psElabMatchWith elaborate (fun current info => do
        -- Resolve and validate this column once, independently of row priority.
        let rows ← rows.mapM fun row => do
          let pattern :: _ := row.patterns | throw .matchPatternUnsupported
          if psElabPatternIrrefutable pattern then return (none, row)
          let pattern := match pattern with
            | .natural value span =>
              if value == 0 then
                PsSyntaxPattern.ctor (PsSyntaxName.mk ["Nat", "zero"] span) [] span
              else .ctor (PsSyntaxName.mk ["Nat", "succ"] span) [.natural (value - 1) span] span
            | _ => pattern
          let row := { row with patterns := pattern :: row.patterns.drop 1 }
          let name ← psElabMatchPatternConstructorName info.name pattern
          if !(info.constructors.any (psNameEq name)) then throw (.matchConstructorUnknown name)
          let some ctor := psEnvironmentFindConstructor current.environment name
            | throw (.matchConstructorUnknown name)
          let count := match pattern with | .ctor _ fields _ => fields.length | _ => 0
          if count != ctor.numFields then throw (.matchConstructorArity name)
          return (some name, row)
        info.constructors.mapM fun name => do
          let some ctor := psEnvironmentFindConstructor current.environment name
            | throw (.matchConstructorUnknown name)
          let span := (psSyntaxTermSpan column.major)
          let fields := (List.range ctor.numFields).map fun index =>
            PsSyntaxName.mk ["$psc0Pattern", psNatToString current.localContext.nextId,
              psNatToString index] span
          let fieldColumns := fields.map fun name =>
            PsElabPatternColumn.mk (.reference name) (.reference name)
          let selected := rows.filterMap fun (head, row) => do
            let pattern :: patterns := row.patterns | none
            if head.isNone then
              let row := psElabPatternBind column pattern row
              some { row with patterns :=
                (fields.map fun _ => PsSyntaxPattern.wildcard span) ++ patterns }
            else if (head.map (psNameEq name)).getD false then
              let children := match pattern with | .ctor _ fields _ => fields | _ => []
              some { row with patterns := children ++ patterns }
            else none
          return {
            constructorName := name
            fieldNames := fields
            elaborate := fun branch target =>
              psElabPatternMatrix fuel elaborate branch (fieldColumns ++ rest) selected target
            span }) context column.major (some expected)

structure PsElabPatternInputs where
  context : PsElabContext
  columns : List PsElabPatternColumn
  locals : List (PsElabTypedBinder × PsExpr)

-- Inaccessible aliases freeze row-binding values before user pattern variables
-- enter scope. Keep original local majors so dependent refinement still sees
-- their original identities; computed discriminants use the alias and run once.
def psElabPatternInputs (elaborate : PsElaborator) (context : PsElabContext)
    (sources : List PsSyntaxTerm) (capture : List Bool) : Except PsElabError PsElabPatternInputs := do
  match sources with
  | [] => return { context, columns := [], locals := [] }
  | source :: rest =>
    let value ← elaborate context source none
    let localReference := match value.term, source with
      | .fvar _, .reference _ => true
      | _, _ => false
    if localReference && !(capture.head?.getD false) then
      let tail ← psElabPatternInputs elaborate value.context rest (capture.drop 1)
      return { tail with columns := { major := source, value := source } :: tail.columns }
    let id := value.context.localContext.nextId
    let span := psSyntaxTermSpan source
    let syntaxName := PsSyntaxName.mk ["$psc0Discriminant", psNatToString id] span
    let some name := psSyntaxNameToName syntaxName | throw .emptyName
    let pushed := psLocalPushLet value.context.localContext name value.type value.term
    let inner := psElabContextWithLocal value.context pushed.context
    let reference := PsSyntaxTerm.reference syntaxName
    let major := match value.term, source with
      | .fvar _, .reference _ => source
      | _, _ => reference
    let tail ← psElabPatternInputs elaborate inner rest (capture.drop 1)
    return {
      context := tail.context
      columns := { major, value := reference } :: tail.columns
      locals := (PsElabTypedBinder.mk pushed.id name value.type .explicit, value.term) :: tail.locals }

def psElabMatchMatrix (elaborate : PsElaborator) (context : PsElabContext)
    (sources : List PsSyntaxTerm)
    (alternatives : List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  let some expected := expected | throw .matchExpectedType
  if sources.isEmpty then throw .matchScrutineeUnsupported
  let rows ← alternatives.mapM fun (patterns, body, span) => do
    if patterns.length != sources.length then throw (.refinement "pattern row/discriminant arity mismatch")
    let names := patterns.flatMap (psSyntaxPatternNames 4096)
    if psSyntaxNameListHasDuplicate names then throw (.refinement "duplicate pattern variable")
    return PsElabPatternRow.mk patterns body span []
  let capture := sources.zipIdx |>.map fun (_, index) =>
    rows.any fun row => match row.patterns[index]? with
      | some (.variable _) => true
      | _ => false
  let inputs ← psElabPatternInputs elaborate context sources capture
  let result ← psElabPatternMatrix 4096 elaborate inputs.context inputs.columns rows expected
  let term := inputs.locals.foldr (fun (binder, value) body =>
    .letE binder.name binder.type value (psExprAbstractFVar binder.id body)) result.term
  return { context := psElabLeaveScope context result.context, term, type := expected }
