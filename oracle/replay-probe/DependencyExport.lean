import Lean
import Std.Data.HashMap.Basic

open Lean
open Std (HashMap)

structure S where
  names : HashMap Name Nat := HashMap.emptyWithCapacity 64 |>.insert .anonymous 0
  levels : HashMap Level Nat := HashMap.emptyWithCapacity 32 |>.insert .zero 0
  exprs : HashMap ExprStructEq Nat := HashMap.emptyWithCapacity 256
  emitted : NameSet := {}
  active : NameSet := {}

abbrev M := StateT S IO

def biJson : BinderInfo → Json
  | .default => "default"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instImplicit => "instImplicit"

@[inline] def intern [Hashable α] [BEq α]
    (x : α) (tag : String)
    (getM : S → HashMap α Nat)
    (setM : S → HashMap α Nat → S)
    (mk : M Json) : M Nat := do
  let m := getM (← get)
  if let some i := m[x]? then return i
  let payload ← mk
  let m := getM (← get)
  let i := m.size
  IO.println (payload.setObjVal! tag i).compress
  modify fun s => setM s ((getM s).insert x i)
  return i

def dumpName (n : Name) : M Nat := intern n "in" (·.names) ({ · with names := · }) do
  match n with
  | .anonymous => unreachable!
  | .str p s =>
    return .mkObj [("str", .mkObj [("pre", ← dumpName p), ("str", s)])]
  | .num p i =>
    return .mkObj [("num", .mkObj [("pre", ← dumpName p), ("i", i)])]

def dumpLevel (l : Level) : M Nat := intern l "il" (·.levels) ({ · with levels := · }) do
  match l with
  | .zero | .mvar _ => unreachable!
  | .succ a => return .mkObj [("succ", ← dumpLevel a)]
  | .max a b => return .mkObj [("max", Json.arr #[← dumpLevel a, ← dumpLevel b])]
  | .imax a b => return .mkObj [("imax", Json.arr #[← dumpLevel a, ← dumpLevel b])]
  | .param n => return .mkObj [("param", ← dumpName n)]

partial def dumpExpr (e : Expr) : M Nat := intern (ExprStructEq.mk e) "ie" (·.exprs) ({ · with exprs := · }) do
  match e with
  | .fvar .. | .mvar .. => throw <| IO.userError "free/meta variable in kernel export"
  | .mdata _ b => return .mkObj [("mdata", .mkObj [("data", .mkObj []), ("expr", ← dumpExpr b)])]
  | .bvar i => return .mkObj [("bvar", i)]
  | .sort l => return .mkObj [("sort", ← dumpLevel l)]
  | .const n us => return .mkObj [("const", .mkObj [("name", ← dumpName n), ("us", (← us.mapM dumpLevel).toJson)])]
  | .app f a => return .mkObj [("app", .mkObj [("fn", ← dumpExpr f), ("arg", ← dumpExpr a)])]
  | .lam n d b bi => return .mkObj [("lam", .mkObj [("name", ← dumpName n), ("type", ← dumpExpr d), ("body", ← dumpExpr b), ("binderInfo", biJson bi)])]
  | .forallE n d b bi => return .mkObj [("forallE", .mkObj [("name", ← dumpName n), ("type", ← dumpExpr d), ("body", ← dumpExpr b), ("binderInfo", biJson bi)])]
  | .letE n d v b _ => return .mkObj [("letE", .mkObj [("name", ← dumpName n), ("type", ← dumpExpr d), ("value", ← dumpExpr v), ("body", ← dumpExpr b)])]
  | .proj s i a => return .mkObj [("proj", .mkObj [("typeName", ← dumpName s), ("idx", i), ("struct", ← dumpExpr a)])]
  | .lit (.natVal n) => return .mkObj [("natVal", s!"{n}")]
  | .lit (.strVal s) => return .mkObj [("strVal", s)]

def dumpUparams (ps : List Name) : M Json := do
  for p in ps do discard <| dumpLevel (.param p)
  return (← ps.mapM dumpName).toJson

def dumpAxiom (ci : AxiomVal) : M Unit := do
  let obj := Json.mkObj [("axiom", Json.mkObj [
    ("name", ← dumpName ci.name),
    ("levelParams", ← dumpUparams ci.levelParams),
    ("type", ← dumpExpr ci.type),
    ("isUnsafe", ci.isUnsafe)
  ])]
  IO.println obj.compress

def dumpTheorem (ci : TheoremVal) : M Unit := do
  let obj := Json.mkObj [("thm", Json.mkObj [
    ("name", ← dumpName ci.name),
    ("levelParams", ← dumpUparams ci.levelParams),
    ("type", ← dumpExpr ci.type),
    ("value", ← dumpExpr ci.value),
    ("all", Json.arr #[])
  ])]
  IO.println obj.compress


def hintsJson : ReducibilityHints → Json
  | .opaque => "opaque"
  | .abbrev => "abbrev"
  | .regular n => .mkObj [("regular", n.toNat)]

def safetyJson : DefinitionSafety → Json
  | .safe => "safe"
  | .unsafe => "unsafe"
  | .partial => "partial"

def dumpNames (ns : List Name) : M Json := return (← ns.mapM dumpName).toJson

def dumpDefinition (ci : DefinitionVal) : M Unit := do
  let obj := Json.mkObj [("def", Json.mkObj [
    ("name", ← dumpName ci.name),
    ("levelParams", ← dumpUparams ci.levelParams),
    ("type", ← dumpExpr ci.type),
    ("value", ← dumpExpr ci.value),
    ("hints", hintsJson ci.hints),
    ("safety", safetyJson ci.safety),
    ("all", ← dumpNames ci.all)
  ])]
  IO.println obj.compress

def dumpInductiveGroup (env : Environment) (indName recName : Name) : M Unit := do
  let some (.inductInfo iv) := env.find? indName | throw <| IO.userError "inductive info missing"
  let mut ctors : Array Json := #[]
  for cn in iv.ctors do
    let some (.ctorInfo cv) := env.find? cn | throw <| IO.userError s!"constructor {cn} missing"
    ctors := ctors.push <| Json.mkObj [
      ("name", ← dumpName cv.name),
      ("levelParams", ← dumpUparams cv.levelParams),
      ("type", ← dumpExpr cv.type),
      ("induct", ← dumpName cv.induct),
      ("cidx", cv.cidx),
      ("numParams", cv.numParams),
      ("numFields", cv.numFields),
      ("isUnsafe", cv.isUnsafe)
    ]
  let some (.recInfo rv) := env.find? recName | throw <| IO.userError "recursor info missing"
  let mut rules : Array Json := #[]
  for rule in rv.rules do
    rules := rules.push <| Json.mkObj [
      ("ctor", ← dumpName rule.ctor),
      ("nfields", rule.nfields),
      ("rhs", ← dumpExpr rule.rhs)
    ]
  let typ := Json.mkObj [
    ("name", ← dumpName iv.name),
    ("levelParams", ← dumpUparams iv.levelParams),
    ("type", ← dumpExpr iv.type),
    ("numParams", iv.numParams),
    ("numIndices", iv.numIndices),
    ("all", ← dumpNames iv.all),
    ("ctors", ← dumpNames iv.ctors),
    ("numNested", iv.numNested),
    ("isRec", iv.isRec),
    ("isUnsafe", iv.isUnsafe),
    ("isReflexive", iv.isReflexive)
  ]
  let recObj := Json.mkObj [
    ("name", ← dumpName rv.name),
    ("levelParams", ← dumpUparams rv.levelParams),
    ("type", ← dumpExpr rv.type),
    ("all", ← dumpNames rv.all),
    ("numParams", rv.numParams),
    ("numIndices", rv.numIndices),
    ("numMotives", rv.numMotives),
    ("numMinors", rv.numMinors),
    ("rules", .arr rules),
    ("k", rv.k),
    ("isUnsafe", rv.isUnsafe)
  ]
  IO.println <| (Json.mkObj [("inductive", Json.mkObj [
    ("types", .arr #[typ]),
    ("ctors", .arr ctors),
    ("recs", .arr #[recObj])
  ])]).compress


def dumpOpaque (ci : OpaqueVal) : M Unit := do
  let obj := Json.mkObj [("opaque", Json.mkObj [
    ("name", ← dumpName ci.name),
    ("levelParams", ← dumpUparams ci.levelParams),
    ("type", ← dumpExpr ci.type),
    ("value", ← dumpExpr ci.value),
    ("isUnsafe", ci.isUnsafe),
    ("all", ← dumpNames ci.all)
  ])]
  IO.println obj.compress

def quotKindJson : QuotKind → Json
  | .type => "type"
  | .ctor => "ctor"
  | .lift => "lift"
  | .ind => "ind"

def dumpQuot (ci : QuotVal) : M Unit := do
  let obj := Json.mkObj [("quot", Json.mkObj [
    ("name", ← dumpName ci.name),
    ("levelParams", ← dumpUparams ci.levelParams),
    ("type", ← dumpExpr ci.type),
    ("kind", quotKindJson ci.kind)
  ])]
  IO.println obj.compress

def isEmitted (n : Name) : M Bool := return (← get).emitted.contains n
def isActive (n : Name) : M Bool := return (← get).active.contains n

def setActive (ns : List Name) : M Unit :=
  modify fun s => { s with active := ns.foldl (init := s.active) fun a n => a.insert n }

def clearActive (ns : List Name) : M Unit :=
  modify fun s => { s with active := ns.foldl (init := s.active) fun a n => a.erase n }

def setEmitted (ns : List Name) : M Unit :=
  modify fun s => { s with emitted := ns.foldl (init := s.emitted) fun a n => a.insert n }

def findCI (env : Environment) (n : Name) : IO ConstantInfo :=
  match env.find? n with
  | some ci => pure ci
  | none => throw <| IO.userError s!"missing constant {n}"

def recursorsFor (env : Environment) (all : List Name) : List RecursorVal := Id.run do
  let mut out := []
  for (_, ci) in env.constants.map₁.toList do
    match ci with
    | .recInfo rv => if rv.all == all then out := rv :: out
    | _ => pure ()
  return out

def dumpInductiveGroupAll (env : Environment) (root : InductiveVal) : M (List Name) := do
  let mut types : Array Json := #[]
  let mut ctors : Array Json := #[]
  let mut emittedNames := root.all
  for tn in root.all do
    let some (.inductInfo iv) := env.find? tn | throw <| IO.userError s!"inductive {tn} missing"
    let mut ctorNames : List Name := []
    for cn in iv.ctors do
      let some (.ctorInfo cv) := env.find? cn | throw <| IO.userError s!"constructor {cn} missing"
      ctorNames := ctorNames ++ [cn]
      emittedNames := emittedNames ++ [cn]
      ctors := ctors.push <| Json.mkObj [
        ("name", ← dumpName cv.name),
        ("levelParams", ← dumpUparams cv.levelParams),
        ("type", ← dumpExpr cv.type),
        ("induct", ← dumpName cv.induct),
        ("cidx", cv.cidx),
        ("numParams", cv.numParams),
        ("numFields", cv.numFields),
        ("isUnsafe", cv.isUnsafe)
      ]
    types := types.push <| Json.mkObj [
      ("name", ← dumpName iv.name),
      ("levelParams", ← dumpUparams iv.levelParams),
      ("type", ← dumpExpr iv.type),
      ("numParams", iv.numParams),
      ("numIndices", iv.numIndices),
      ("all", ← dumpNames iv.all),
      ("ctors", ← dumpNames ctorNames),
      ("numNested", iv.numNested),
      ("isRec", iv.isRec),
      ("isUnsafe", iv.isUnsafe),
      ("isReflexive", iv.isReflexive)
    ]
  let mut recs : Array Json := #[]
  for rv in recursorsFor env root.all do
    emittedNames := emittedNames ++ [rv.name]
    let mut rules : Array Json := #[]
    for rule in rv.rules do
      rules := rules.push <| Json.mkObj [
        ("ctor", ← dumpName rule.ctor),
        ("nfields", rule.nfields),
        ("rhs", ← dumpExpr rule.rhs)
      ]
    recs := recs.push <| Json.mkObj [
      ("name", ← dumpName rv.name),
      ("levelParams", ← dumpUparams rv.levelParams),
      ("type", ← dumpExpr rv.type),
      ("all", ← dumpNames rv.all),
      ("numParams", rv.numParams),
      ("numIndices", rv.numIndices),
      ("numMotives", rv.numMotives),
      ("numMinors", rv.numMinors),
      ("rules", .arr rules),
      ("k", rv.k),
      ("isUnsafe", rv.isUnsafe)
    ]
  IO.println <| (Json.mkObj [("inductive", Json.mkObj [
    ("types", .arr types), ("ctors", .arr ctors), ("recs", .arr recs)
  ])]).compress
  return emittedNames

def natLeConditionDeps : List Name := [
  "Bool.false".toName, "Bool.true".toName, "Eq".toName, "Bool.decEq".toName,
  "Nat.ble".toName, "LE".toName, "LE.le".toName, "instLENat".toName,
  "Decidable".toName, "Decidable.isTrue".toName, "Decidable.isFalse".toName,
  "Not".toName, "dite".toName, "Nat.decLe".toName,
  "Nat.le_of_ble_eq_true".toName, "Nat.not_le_of_not_ble_eq_true".toName
]

def semanticDeps (n : Name) : List Name :=
  if n == "Nat.div".toName then
    ["Nat.div.go".toName, "Nat.div_rec_fuel_lemma".toName, "Nat.lt_succ_self".toName] ++ natLeConditionDeps
  else if n == "Nat.mod".toName then
    ["Nat.modCore.go".toName, "Nat.div_rec_fuel_lemma".toName, "Nat.lt_succ_self".toName, "ite".toName] ++ natLeConditionDeps
  else
    []

mutual
  partial def dumpConstant (env : Environment) (name : Name) : M Unit := do
    if ← isEmitted name then return
    if ← isActive name then return
    for dep in semanticDeps name do dumpConstant env dep
    let ci ← findCI env name
    match ci with
    | .ctorInfo cv => dumpConstant env cv.induct
    | .recInfo rv =>
      match rv.all with
      | h :: _ => dumpConstant env h
      | [] => throw <| IO.userError s!"recursor {name} has empty all-list"
    | .inductInfo iv =>
      setActive iv.all
      -- Constructors carry all external dependencies of the declaration that matter for replay.
      for tn in iv.all do
        let some (.inductInfo tv) := env.find? tn | throw <| IO.userError s!"inductive {tn} missing"
        let tci ← findCI env tn
        dumpConstants env tci.getUsedConstantsAsSet
        for cn in tv.ctors do
          let cci ← findCI env cn
          dumpConstants env cci.getUsedConstantsAsSet
      let emitted ← dumpInductiveGroupAll env iv
      setEmitted emitted
      clearActive iv.all
    | .defnInfo dv =>
      let group := if dv.all.isEmpty then [dv.name] else dv.all
      setActive group
      for n in group do
        let some (.defnInfo _) := env.find? n | throw <| IO.userError s!"mutual definition member {n} missing"
        let ci ← findCI env n
        dumpConstants env ci.getUsedConstantsAsSet
      for n in group do
        let some (.defnInfo d) := env.find? n | throw <| IO.userError s!"mutual definition member {n} missing"
        dumpDefinition d
      setEmitted group
      clearActive group
    | .axiomInfo av =>
      setActive [name]
      dumpConstants env ci.getUsedConstantsAsSet
      dumpAxiom av
      setEmitted [name]
      clearActive [name]
    | .thmInfo tv =>
      setActive [name]
      dumpConstants env ci.getUsedConstantsAsSet
      dumpTheorem tv
      setEmitted [name]
      clearActive [name]
    | .opaqueInfo ov =>
      setActive [name]
      dumpConstants env ci.getUsedConstantsAsSet
      dumpOpaque ov
      setEmitted [name]
      clearActive [name]
    | .quotInfo qv =>
      setActive [name]
      dumpConstants env ci.getUsedConstantsAsSet
      dumpQuot qv
      setEmitted [name]
      clearActive [name]

  partial def dumpConstants (env : Environment) (names : NameSet) : M Unit := do
    for n in names do dumpConstant env n
end


def resetInternTables : M Unit :=
  modify fun s => { s with
    names := HashMap.emptyWithCapacity 64 |>.insert .anonymous 0
    levels := HashMap.emptyWithCapacity 32 |>.insert .zero 0
    exprs := HashMap.emptyWithCapacity 256
    active := {}
  }

def dumpMeta : IO Unit :=
  IO.println <| (Json.mkObj [("meta", Json.mkObj [
    ("exporter", Json.mkObj [("name", "dependency-closure"), ("version", "1")]),
    ("lean", Json.mkObj [("githash", githash), ("version", versionString)]),
    ("format", Json.mkObj [("version", "3.1.0")])
  ])]).compress

def rootsForModule (env : Environment) (idx : ModuleIdx) : List Name := Id.run do
  let mut roots := []
  for (n, _) in env.constants.map₁.toList do
    if env.getModuleIdxFor? n == some idx then roots := n :: roots
  return roots

def collectRootsByModule (env : Environment) : Array (Array Name) := Id.run do
  let mut buckets := Array.replicate env.header.moduleNames.size #[]
  for (n, _) in env.constants.map₁.toList do
    if let some idx := env.getModuleIdxFor? n then
      buckets := buckets.modify idx (fun xs => xs.push n)
  for idx in [0:buckets.size] do
    buckets := buckets.set! idx (buckets[idx]!.qsort Name.quickLt)
  return buckets

def batchSizes (buckets : Array (Array Name)) (maxRoots : Nat) : Array Nat := Id.run do
  let mut sizes := #[]
  let mut count := 0
  for roots in buckets do
    for _ in roots do
      if count == maxRoots then
        sizes := sizes.push count
        count := 0
      count := count + 1
  if count > 0 then sizes := sizes.push count
  return sizes

def selectedBatchRoots (sizes : Array Nat) (start count : Nat) : Nat := Id.run do
  let stop := if count == 0 then sizes.size else min sizes.size (start + count)
  let mut total := 0
  for i in [start:stop] do total := total + sizes[i]!
  return total

def dumpBatchManifest (env : Environment) (target : Name) (maxRoots : Nat) : IO Unit := do
  if maxRoots == 0 then throw <| IO.userError "batch size must be positive"
  let buckets := collectRootsByModule env
  let sizes := batchSizes buckets maxRoots
  let directRoots := sizes.foldl (· + ·) 0
  if directRoots != env.constants.map₁.size then
    throw <| IO.userError s!"batch root coverage mismatch: {directRoots} != {env.constants.map₁.size}"
  IO.println <| (Json.mkObj [("environment", Json.mkObj [
    ("module", target.toString),
    ("constants", env.constants.map₁.size),
    ("modules", env.header.moduleNames.size),
    ("batches", sizes.size),
    ("maxRoots", maxRoots),
    ("batchSizes", Json.arr <| sizes.map fun n => toJson n)
  ])]).compress

partial def dumpBatchStream (env : Environment) (target : Name) (maxRoots startBatch batchLimit : Nat) : IO Unit := do
  if maxRoots == 0 then throw <| IO.userError "batch size must be positive"
  let buckets := collectRootsByModule env
  let sizes := batchSizes buckets maxRoots
  let directRoots := sizes.foldl (· + ·) 0
  if directRoots != env.constants.map₁.size then
    throw <| IO.userError s!"batch root coverage mismatch: {directRoots} != {env.constants.map₁.size}"
  let stopBatch := if batchLimit == 0 then sizes.size else min sizes.size (startBatch + batchLimit)
  let selectedRoots := selectedBatchRoots sizes startBatch batchLimit
  IO.println <| (Json.mkObj [("environment", Json.mkObj [
    ("module", target.toString),
    ("constants", env.constants.map₁.size),
    ("modules", env.header.moduleNames.size),
    ("batches", sizes.size),
    ("maxRoots", maxRoots),
    ("rangeStart", startBatch),
    ("rangeStop", stopBatch),
    ("selectedBatches", stopBatch - min startBatch stopBatch),
    ("selectedDirectRoots", selectedRoots)
  ])]).compress
  let mut pending : Array Name := #[]
  let mut firstModule := ""
  let mut lastModule := ""
  let mut batchIdx : Nat := 0
  let flush (roots : Array Name) (idx : Nat) (first last : String) : IO Unit := do
    unless roots.isEmpty do
      if idx >= startBatch && idx < stopBatch then
        IO.println <| (Json.mkObj [("batch", Json.mkObj [
          ("index", idx),
          ("firstModule", first),
          ("lastModule", last),
          ("directRoots", roots.size)
        ])]).compress
        let _ ← (do
          let segmentRoots : Nat := 50
          let mut segment : Nat := 0
          let mut inSegment : Nat := 0
          for n in roots do
            if inSegment == 0 then
              resetInternTables
              IO.println <| (Json.mkObj [("segment", Json.mkObj [
                ("index", segment),
                ("maxDirectRoots", segmentRoots)
              ])]).compress
              dumpMeta
            dumpConstant env n
            inSegment := inSegment + 1
            if inSegment == segmentRoots then
              segment := segment + 1
              inSegment := 0) |>.run {}
        pure ()
  for idx in [0:buckets.size] do
    let roots := buckets[idx]!
    if roots.isEmpty then continue
    let mn := env.header.moduleNames[idx]!.toString
    for n in roots do
      if pending.size == maxRoots then
        flush pending batchIdx firstModule lastModule
        pending := #[]
        firstModule := ""
        batchIdx := batchIdx + 1
      if pending.isEmpty then firstModule := mn
      lastModule := mn
      pending := pending.push n
  flush pending batchIdx firstModule lastModule

partial def dumpModuleStream (env : Environment) (target : Name) : IO Unit := do
  let total := env.constants.map₁.size
  IO.println <| (Json.mkObj [("environment", Json.mkObj [
    ("module", target.toString),
    ("constants", total),
    ("modules", env.header.moduleNames.size)
  ])]).compress
  let buckets := collectRootsByModule env
  let _ ← (do
    for idx in [0:buckets.size] do
      let roots : Array Name := buckets[idx]!
      unless roots.isEmpty do
        resetInternTables
        let moduleName := env.header.moduleNames[idx]!
        IO.println <| (Json.mkObj [("shard", Json.mkObj [
          ("module", moduleName.toString),
          ("index", idx),
          ("roots", roots.size)
        ])]).compress
        dumpMeta
        for n in roots do dumpConstant env n) |>.run {}
  pure ()

unsafe def main (args : List String) : IO Unit := do
  initSearchPath (← findSysroot)
  if args.length < 2 then
    throw <| IO.userError "usage: DependencyExport <module> <root>..."
  let moduleName := args.head!.toName
  let requestedRoots := args.tail!
  withImportModules #[{module := moduleName}] {} fun env => do
    let roots :=
      if requestedRoots == ["--all"] then env.constants.map₁.toList.map (·.1)
      else requestedRoots.map String.toName
    if requestedRoots == ["--module-stream"] then
      dumpModuleStream env moduleName
    else if requestedRoots.length == 2 && requestedRoots.head! == "--batch-manifest" then
      let maxRoots := requestedRoots.tail!.head! |>.toNat!
      dumpBatchManifest env moduleName maxRoots
    else if requestedRoots.length == 2 && requestedRoots.head! == "--batch-stream" then
      let maxRoots := requestedRoots.tail!.head! |>.toNat!
      dumpBatchStream env moduleName maxRoots 0 0
    else if requestedRoots.length == 4 && requestedRoots.head! == "--batch-range" then
      let maxRoots := requestedRoots[1]!.toNat!
      let start := requestedRoots[2]!.toNat!
      let count := requestedRoots[3]!.toNat!
      dumpBatchStream env moduleName maxRoots start count
    else
      dumpMeta
      let _ ← (do
        for n in roots do dumpConstant env n) |>.run {}
      pure ()
