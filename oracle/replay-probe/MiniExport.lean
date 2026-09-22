import Lean
import Std.Data.HashMap.Basic

open Lean
open Std (HashMap)

structure S where
  names : HashMap Name Nat := HashMap.emptyWithCapacity 64 |>.insert .anonymous 0
  levels : HashMap Level Nat := HashMap.emptyWithCapacity 32 |>.insert .zero 0
  exprs : HashMap ExprStructEq Nat := HashMap.emptyWithCapacity 256

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

unsafe def main : IO Unit := do
  initSearchPath (← findSysroot)
  withImportModules #[{module := `ReplayProbe}] {} fun env => do
    IO.println <| (Json.mkObj [("meta", Json.mkObj [
      ("exporter", Json.mkObj [("name", "mini-probe"), ("version", "0")]),
      ("lean", Json.mkObj [("githash", githash), ("version", versionString)]),
      ("format", Json.mkObj [("version", "3.1.0")])
    ])]).compress
    let a := env.find? `ReplayProbe.A
    let id := env.find? `ReplayProbe.id
    let one := env.find? `ReplayProbe.one
    let singleton := env.find? `ReplayProbe.singleton
    let vecOne := env.find? `ReplayProbe.vecOne
    match a, id, one, singleton, vecOne with
    | some (.axiomInfo av), some (.thmInfo tv), some (.defnInfo dv), some (.defnInfo sv), some (.defnInfo vv) =>
      let _ ← (do
        dumpAxiom av
        dumpTheorem tv
        dumpInductiveGroup env `ReplayProbe.MiniNat `ReplayProbe.MiniNat.rec
        dumpDefinition dv
        dumpInductiveGroup env `ReplayProbe.MiniList `ReplayProbe.MiniList.rec
        dumpDefinition sv
        dumpInductiveGroup env `ReplayProbe.MiniVec `ReplayProbe.MiniVec.rec
        dumpDefinition vv) |>.run {}
      pure ()
    | _, _, _, _, _ => throw <| IO.userError "probe declarations not found with expected kinds"
