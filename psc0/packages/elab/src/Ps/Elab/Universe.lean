import Ps.Elab.Basic

def psElabLevelOffset (level : PsLevel) : Nat → PsLevel
  | 0 => level
  | n + 1 => .succ (psElabLevelOffset level n)

def psElabLevel (context : PsElabContext) (levelSyntax : PsSyntaxLevel) :
    Except PsElabError (PsElabContext × PsLevel) := do
  match levelSyntax with
  | .number n => return (context, psElabLevelOffset .zero n)
  | .name name =>
    let value := psRootName name
    if !context.levelNames.any (psNameEq value) then
      throw (.scope ("unknown universe " ++ name))
    return (context, .param value)
  | .qualifiedName segments =>
    if segments.isEmpty then throw (.scope "empty universe name")
    let value := psSyntaxNameAppendSegments segments .anonymous
    if !context.levelNames.any (psNameEq value) then
      throw (.scope ("unknown universe " ++ psNameToString value))
    return (context, .param value)
  | .hole =>
    let fresh := psMetaFreshLevel context.metaContext
    return (psElabContextWithMeta context fresh.context, fresh.level)
  | .offset base n =>
    let (context, base) ← psElabLevel context base
    return (context, psElabLevelOffset base n)
  | .max left right | .imax left right =>
    let (context, left) ← psElabLevel context left
    let (context, right) ← psElabLevel context right
    return (context, match levelSyntax with | .max _ _ => .max left right | _ => .imax left right)

def psElabSort (context : PsElabContext) (isType : Bool) (levelSyntax : PsSyntaxLevel)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  let (context, level) ← psElabLevel context levelSyntax
  psElabResolvedTerm context (.sortE (if isType then .succ level else level)) expected

def psElabLevelParams : PsLevel → List PsName
  | .zero | .mvar _ => []
  | .param name => [name]
  | .succ level => psElabLevelParams level
  | .max a b | .imax a b => psElabLevelParams a ++ psElabLevelParams b

def psElabExprLevels : PsExpr → List PsLevel
  | .sortE level => [level]
  | .constE _ levels => levels
  | .app a b | .lam _ a b _ | .forallE _ a b _ => psElabExprLevels a ++ psElabExprLevels b
  | .letE _ a b c => psElabExprLevels a ++ psElabExprLevels b ++ psElabExprLevels c
  | .proj _ _ value => psElabExprLevels value
  | _ => []

def psElabUsedLevels (available : List PsName) (expressions : List PsExpr) : List PsName :=
  let used := expressions.flatMap fun e => (psElabExprLevels e).flatMap psElabLevelParams
  available.filter fun name => used.any (psNameEq name)

-- Native expandDeclId binds every suffix only in its own declaration.
-- Original mutual main headers must present the same ordered universe list.
-- Source components become string components; no spelling can create a num.
def psElabDeclarationUniverseNames (scopeLevels : List PsName)
    (names : List PsSyntaxName) : Except PsElabError (List PsName) := do
  let lists ← names.mapM fun sourceName =>
    sourceName.universeBinders.foldlM (fun levels binder => do
      if binder.segments.isEmpty || (!binder.escaped && binder.segments == ["_"]) then
        throw (.scope "PSCV0-DECL-UNIVERSE-NAME: invalid universe parameter")
      let name := psSyntaxNameAppendSegments binder.segments .anonymous
      if levels.any (psNameEq name) then
        throw (.scope ("PSCV0-DECL-UNIVERSE-DUPLICATE: universe already declared " ++ psNameToString name))
      return levels ++ [name]) scopeLevels
  let first :: remaining := lists | return scopeLevels
  if remaining.any (fun levels =>
      levels.length != first.length ||
        !(levels.zip first).all (fun pair => psNameEq pair.1 pair.2)) then
    throw (.scope "PSCV0-DECL-UNIVERSE-MUTUAL: universe parameters mismatch")
  return first

-- Command universes may be unused. Explicit .{...} parameters must occur in
-- the complete closed declaration/block before dependency partitioning.
def psElabCheckDeclarationUniverseUsage (names : List PsSyntaxName)
    (expressions : List PsExpr) : Except PsElabError Unit := do
  if names.all (fun name => name.universeBinders.isEmpty) then return ()
  let used := expressions.flatMap fun expression =>
    (psElabExprLevels expression).flatMap psElabLevelParams
  for sourceName in names do
    for binder in sourceName.universeBinders do
      let name := psSyntaxNameAppendSegments binder.segments .anonymous
      if !used.any (psNameEq name) then
        throw (.scope ("PSCV0-DECL-UNIVERSE-UNUSED: unused universe parameter " ++ psNameToString name))

-- Fresh universe holes are generalized at a declaration boundary, never at a
-- use site. Numeric internal names cannot collide with source universe names.
def psElabGeneralizeLevel : PsLevel → PsLevel
  | .mvar id => .param (psNameAppendNum (psRootName "_universe") id)
  | .succ level => .succ (psElabGeneralizeLevel level)
  | .max a b => .max (psElabGeneralizeLevel a) (psElabGeneralizeLevel b)
  | .imax a b => .imax (psElabGeneralizeLevel a) (psElabGeneralizeLevel b)
  | level => level

def psElabGeneralizeExpr : PsExpr → PsExpr
  | .sortE level => .sortE (psElabGeneralizeLevel level)
  | .constE name levels => .constE name (levels.map psElabGeneralizeLevel)
  | .app a b => .app (psElabGeneralizeExpr a) (psElabGeneralizeExpr b)
  | .lam name a b binder => .lam name (psElabGeneralizeExpr a) (psElabGeneralizeExpr b) binder
  | .forallE name a b binder => .forallE name (psElabGeneralizeExpr a) (psElabGeneralizeExpr b) binder
  | .letE name a b c => .letE name (psElabGeneralizeExpr a) (psElabGeneralizeExpr b) (psElabGeneralizeExpr c)
  | .proj name index value => .proj name index (psElabGeneralizeExpr value)
  | expr => expr

def psElabDeclarationLevels (available : List PsName) (expressions : List PsExpr) : List PsName :=
  let used := expressions.flatMap fun e => (psElabExprLevels e).flatMap psElabLevelParams
  used.foldl (fun names name => if names.any (psNameEq name) then names else names ++ [name])
    (psElabUsedLevels available expressions)
